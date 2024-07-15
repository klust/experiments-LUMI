/* Show thread affinity
    Copyright (C) Harvey Richardson, April 2010, Jan 2014, Mar 2015, Apr 2016
    Copyright (C) 2021,2023 Hewlett Packard Enterprise Development LP
    Linux only.

    Needs GNU and GLIBC stuff so hard with other compilers
    Note that /proc/self/stat only gives lastcpu per process so
    seems to give cpu for first thread if you are multithreaded.
    Using sched_getcpu() seems better

    This has no optimizations for efficiency and in particular
    uses rank to rank communication instead of gather.

    Version string in help source.
 
 */

#ifdef __llvm__
#pragma GCC diagnostic ignored "-Wdangling-else"
#endif

#define ACHECK_VERSION "v1.51"
#define ONCPU_DEFAULT 0 // show oncpu information
#define SHOW_MASK_DEFAULT 0 // show ASCII binding mask
#define SHOW_NUMERIC_MASK_DEFAULT 1 // show numeric mask format
#define USE_GETTID      // Compile support for getttid    
#define GETTID_DEFAULT 0 // show taskid from OS
#define REPORT_OVER_THREADED 0 // Report if ranks have too many threads
#include <stdio.h>
#include <stdlib.h>

#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include <mpi.h>

#ifdef NEW_VERSION
// This is a real mess,  Looks like you have to set __USE_GNU to get the macros, PGI does not need this
#define _GNU_SOURCE
#define __USE_GNU
#endif
#include <sched.h>

#ifdef NEW_VERSION_PGIFIX
# define CPU_ZERO(cpusetp)       __CPU_ZERO_S (sizeof (cpu_set_t), cpusetp)
#endif

#ifdef USE_GETTID
#include <sys/types.h>
#include <sys/syscall.h>
#define gettid() syscall(SYS_gettid)
//#include <pthread.h>
//#define gettid() pthread_self()
#endif

// This should be set from compiler options/Makefile
#ifdef ACCEL_SUPPORT_ROCR
#include <hip/hip_runtime.h>
#endif

#define max(a,b) ((a) < (b) ? (b) : (a))
#define min(a,b) ((a) > (b) ? (b) : (a))
#define IWIDTH(v) ( (v) > 1 ?  ((int)(floor(log10((double)(v)))) +1 ) : (1))

#define MAXHOSTNAME 100
#define MAXRANKLINEWIDTH 72
#define ENV_MAXSIZE 20
#define LABEL_MAXSIZE 80
// #define MASK_MAXSIZE 128  // naximum possibe number of cpus
// #define MASK_MAXSIZE 272  // naximum possibe number of cpus  KNL!
#define MASK_MAXSIZE CPU_SETSIZE  // This shoud be the right fix
#define IMASK_MAXSIZE CPU_SETSIZE*4  // worst is 0 2 4 6... xxx
#define MAXLINE 100

static char *switches[]={"-v",
                         "-byrank",
                         "-numa",
                         "-amask",
                         "-nmask",
                         "-split_mask",
                         "-oncpu",
                         "-tid",
                         "-h",
                         "-label",
			 "-gpu",
                         ""}; /* MUST end with null */

typedef enum snum {
   sw_invalid,
   sw_v,
   sw_byrank,
   sw_numa,
   sw_amask,
   sw_nmask,
   sw_split_mask,
   sw_oncpu,
   sw_tid,
   sw_h,
   sw_label,
   sw_gpu,
  } snum_e;  /* These MUST match switches order above */


typedef enum mask_format {
   FORMAT_DEFAULT,
   FORMAT_FILLED,
  } mask_format_e;  

// Because we might incorporate this into MPI test program
typedef struct cpu_binding_t {
  int cpu;   // Which cpu are we bound to if there is only one otherwise -1
  int ncpu;  // How many cpus are in the mask we have
  char *mask; // ASCII encoded mask
  // really need to rename next two
  char *integer_mask;  // ASCII Mask but as list of integers or ranges of integers
  char *integer_numa_mask; // ASCII Mask as list of integers or ranges of numa regions
} cpu_binding_s,*cpu_binding_p;

typedef struct hostinfo_t {
  char *name;
  int *ranks;
  int nranks;
  struct hostinfo_t *next;
} hostinfo_s,*hostinfo_p;

typedef struct threadinfo_t {
  int omp_tid;
#ifdef USE_GETTID
  int tid; // this is from the OS
#endif
  struct cpu_binding_t binding;  
} threadinfo_s,*threadinfo_p;

typedef struct gpuinfo_t {
  int ngpus;
  char *env_cuda_visible_devices;
  char *env_hip_visible_devices;
  char *env_rocr_visible_devices;
  char *HIP_devicelist;
  char *HIP_pcibusidlist;
  char *numa_nodelist;
} gpuinfo_s,*gpuinfo_p;

typedef struct rankinfo_t {
  hostinfo_p hostinfo;      // connect rank to host
  char *label;              // launch process(rank) label (for MPMD)
  int nthreads;             // As seen by OMP team
  int process_threadcount;  // threads per linux process
  char *env_ont;            // OMP_NUM_THREADS
  threadinfo_p threadinfo;
  struct gpuinfo_t gpuinfo;
} rankinfo_s,*rankinfo_p;

static int verbose=0;
static int use_label=0;
static int nhosts=0;
static int show_gpu=0;
static int show_gpu_envs=0;

snum_e get_switch_num(char *str)

  {
    char **sw;
    int i=1;

    sw=switches;
    while(**sw!=0){
      if (strcmp(str,*sw)==0) {
	return (snum_e)i;
      }
      sw++;i++;
    }

    return sw_invalid;

  }

void do_help()
{
  fprintf(stderr,
   "acheck\n\n"
   "Switches accepted\n"
   " -h            produce help information and exit\n"
   " -v            be verbose about rank mappings, show binding\n"
   " -byrank       order binding info by rank rather than host\n"
   " -numa         encode NUMA mapping in ASCII binding map\n"
   " -amask        toggle display of ASCII-encoded binding mask\n"
   " -nmask        enable display of numeric binding mask\n"
   " -split_mask   Split the mask into two - useful for systems\n"
   "               with hyperthreads (experimental)\n"
   " -oncpu        Toggle display of 'oncpu' column to enable/disable\n"
   " -label        Display a label for each process\n"
   "\n"
   "This program prints out useful information on the distribution\n"
   "of processes in an MPI application.\n"
   "It also provides information on OpenMP threading and detailed\n"
   "information on how threads are bound to cpus on each host\n\n"
   "It can also be used to debug MPMD launches using the -label flag,\n"
   "the label either comes from the environment variable ACHECK_LABEL\n"
   "or from argv[0]\n"
   "\n\n"
          );
}

void get_args(int            argc,
	      char         **argv,
              int           *byrank,
              int           *show_mask,
              int           *show_numeric_mask,
              int           *show_numa,
              int           *split_mask,
              int           *show_oncpu,
              int           *show_tid,
              int           *use_label,
	      int           *show_gpu,
	      int           *show_gpu_envs)
{
  snum_e snum;
  char **arg;
  char *arg0;
  int i,p_no;

  arg0=*argv++; argc--; /* remove program name */
  arg=argv;

  while(argc--){
    snum = get_switch_num(*argv);
    switch(snum){
    case sw_v:
      verbose = max(1,verbose);
      break;
    case sw_byrank:
      *byrank = 1;
      break;
    case sw_numa:
      *show_numa = 1;
      break;
    case sw_amask:
      if (*show_mask){
        *show_mask = 0;
      } else {
        *show_mask = 1;
      }
      break;
    case sw_nmask:
      *show_numeric_mask = 1;
      break;
    case sw_split_mask:
      *split_mask *= 2;
      break;
    case sw_oncpu:
      *show_oncpu = ! *show_oncpu;
      break;
    case sw_tid:
      *show_tid = 1;
      break;
    case sw_label:
      *use_label = 1;
      break;
    case sw_gpu:
      *show_gpu = 1;
      *show_gpu_envs = 1;
      break;
    case sw_h:
      do_help();
      // Need to broadcast something and finalise in main
      break;
    case sw_invalid:
      break;
    }
    argv++;
  }

}

hostinfo_p create_hostinfo(hostinfo_p start,
                           char *host){

  hostinfo_p hi;
  int len;

  len=strlen(host);

  //  printf("create_hostinfo: for %s\n",host);
  if (start==NULL){
    start=(hostinfo_p)calloc((size_t)1,(size_t)sizeof(hostinfo_s));
    start->name=(char *)malloc((size_t)len*sizeof(char));
    strcpy(start->name,host);
    nhosts++;
    //    printf("create_hostinfo: created first node for %s\n",host);
    return start;
   } else {

    hi=start;
    //    printf("create_hostinfo: hostinfo->host=%s\n",start->name);
    if (strcmp(start->name,host)==0) {
      //      printf("create_hostinfo: hostinfo argument match %s\n",host);
      return hi;
    }
    //    printf("create_hostinfo: searching %s\n",host);

    while(hi->next!=NULL){
      hi=hi->next;
      if (strcmp(hi->name,host)==0) return hi;
    }

    //    printf("create_hostinfo: search failed, crating %s\n",host);

    /* This means we did not match */
    hi->next=(hostinfo_p)calloc((size_t)1,(size_t)sizeof(hostinfo_s));
    hi=hi->next;
    hi->name=(char *)malloc((size_t)len*sizeof(char));
    strcpy(hi->name,host);
    nhosts++;
    return hi;
  }



}


static void print_hostmap(hostinfo_p hostinfo,rankinfo_p rankinfo, 
                          int size,
                          int rank_w, int host_w){
  hostinfo_p hi;
  int r,rcount,rc;
  
  rcount=(MAXRANKLINEWIDTH-host_w-2)/(rank_w+1);
  hi=hostinfo;
  printf("\n %*s %*s\n",host_w,"Host",rank_w,"Ranks...");
  do {
    printf(" %*s",host_w,hi->name);
    for(r=0,rc=0;r<hi->nranks;r++,rc++){
      if (rc>rcount-1){
        printf("\n%*s",host_w+1," ");
	rc=0;
      }
      printf(" %*d",rank_w,hi->ranks[r]);
    }
    printf("\n");
    hi=hi->next;
   } while (hi!=NULL);

   printf("\n");

}

// retrun mapping of cpu to NUMA node
// set mapping to -1 if no numa nodes
// and return number of numa nodes found

#define MAX_NUMA_NODES 64
int get_numa_map(int *cpu_to_node,
                 int n,
                 int maxcpu){
  int node,nnodes,cpu;

  nnodes=0;
  /* Clear the CPU to node list. */
  for (cpu=0;cpu < maxcpu;cpu++) cpu_to_node[cpu] = -1;

  for (node=0;node < MAX_NUMA_NODES;node++) {
    char fname[40],line[100];
    FILE *fp;
    char *s;
    int cpu1, cpu2, cpu;
    // Each file has comma separed ranges of cpus 
    sprintf(fname,"/sys/devices/system/node/node%d/cpulist",node);
    if ((fp=fopen(fname,"r")) == NULL) break;   /* no more NUMA nodes */

    if (fgets(line,sizeof(line),fp) == NULL){
       break;
     }
    nnodes=node+1;
    s=strtok(line,",");
    while (s!=NULL){
      if (sscanf(s,"%d-%d",&cpu1,&cpu2)==2){
        for(cpu=cpu1;cpu<=cpu2;cpu++) cpu_to_node[cpu] = node;
      } else if (sscanf(s,"%d",&cpu)==1) cpu_to_node[cpu] = node;
      s=strtok(NULL,",");
     }
    
    fclose(fp);
  }

  return nnodes;

}

// By inspection from CSM/COS AMD GPU node
int get_gpu_numa_node(char *node,char *pcibusid){
  char *fname;
  char *pattern="/sys/module/amdgpu/drivers/pci:amdgpu/%s/numa_node";
  FILE *fp;
  char line[MAXLINE];
  
  fname=(char *)malloc((size_t)(strlen(pattern)+strlen(pcibusid)+1));
  sprintf(fname,pattern,pcibusid);

  if ((fp=fopen(fname,"r")) == NULL) return EXIT_FAILURE;

  if (fgets(line,sizeof(line),fp) == NULL) return EXIT_FAILURE;

  line[strcspn(line,"\n")]=0;
  strcpy(node,line);
  free(fname);
  return EXIT_SUCCESS;
}


// number of cpus as seen by linux in /proc
int getnumcpus(){
  FILE *fp;
  char line[MAXLINE];
  char *c;
  int ncpu=0;

  if ((fp=fopen("/proc/cpuinfo","r"))!=NULL){

    while(fgets(line,MAXLINE,fp)!=NULL ){
      if (strncmp(line,"processor",9)==0){
        c=strchr(line,':');
        ncpu=strtod(++c,NULL);
      }
    }
    fclose(fp);
    if (ncpu>0) ncpu = ncpu+1; // counted from 0
  }

  return ncpu;
}

int get_process_threadcount(){
  FILE *fp;
  char line[MAXLINE];
  char *c;
  int threads=0;

  if ((fp=fopen("/proc/self/status","r"))!=NULL){

    while(fgets(line,MAXLINE,fp)!=NULL ){
      if (strncmp(line,"Threads",7)==0){
        c=strchr(line,':');
        threads=strtod(++c,NULL);
      }
    }
    fclose(fp);
  }

  return threads;

}

// last CPU we were scheduled on, note this can change if there
// is no binding and the data comes from /proc.
// return <0 if we can't get the data
int getlastcpu(){

  FILE *fp;
  char line[256];
  char *s;
  int token=39;
  int cpu;

#ifdef HAVE_GETCPU
  return sched_getcpu();
#else
  if ((fp=fopen("/proc/self/stat","r")) ==NULL ){
      return -1;
    }
  if (fgets(line,sizeof(line),fp) == NULL){
      return -1;
    }
  fclose(fp);
  strtok(line," ");
  while (--token>0){
    s=strtok(NULL," ");
   }
  sscanf(s,"%d",&cpu);

  return cpu;
#endif

}


void getaffinity(cpu_binding_s *b,mask_format_e format,int ncpus,
                 int show_numa,int *cpu_to_numa){
  cpu_set_t mask;
  int i;
  int nset;

  CPU_ZERO(&mask);
  if (sched_getaffinity(0,sizeof(mask),&mask) == -1 ){
    perror("main sched_getaffinity");

  }

  b->cpu=-1;
  b->ncpu=0;
  for(i=0;i<CPU_SETSIZE;i++){
    if (CPU_ISSET(i,&mask)){
      b->cpu=i;
      b->ncpu++;
    }
   }
  if (format == FORMAT_FILLED) {
    b->mask=(char *)malloc((size_t)(ncpus+1)*sizeof(char));
   } else {
    b->mask=(char *)malloc((b->cpu)+2);
   }
  for (i=0;i<=b->cpu;i++){
    if (CPU_ISSET(i,&mask)){
      if (show_numa){
       // Warning - this only works for up to 10 numa nodes otherwise
       // we end up with the ASCII characters following '9'
       b->mask[i]='0'+cpu_to_numa[i];
      } else {
       b->mask[i]='1';
      }
    } else {
      b->mask[i]='.';
    }
  }
  if (format == FORMAT_FILLED){
    for(;i<ncpus;i++)b->mask[i]='.';
  }
  b->mask[i]=0;
  if (b->ncpu >1) { b->cpu=-1; }

}

// Based on code from Tom, Harvey, Tim
void get_compiler_info(char *info,int n){

#if defined(_CRAYC)
  sprintf(info,"%s", _RELEASE_STRING);
#elif defined(__cray__)
  sprintf(info, "CCE/Clang %d.%d.%d", __cray_major__,
                __cray_minor__, __cray_patchlevel__);
#elif defined(__clang__)
  sprintf(info, "Clang %d.%d.%d", __clang_major__,
                __clang_minor__, __clang_patchlevel__);
#elif defined(__ICC)
  sprintf(info,"Intel Compiler %d", __INTEL_COMPILER);
#elif defined(__PGI)
  sprintf(info,"PGI C %d.%d-%d",__PGIC__,
               __PGIC_MINOR__,__PGIC_PATCHLEVEL__);
#elif defined(__GNUC__)
  sprintf(info,"GNU %d.%d.%d\n", __GNUC__,
                __GNUC_MINOR__, __GNUC_PATCHLEVEL__);
#endif


}


/* Create an mask that is make up of integer ranges from the 
   mask that encodes cpus with 1s as in "....111....1...   
   or that encodes with numa reagions   "....122....3...
   We get the second if numa info was requested
*/
void make_imask(char **integer_mask, char *mask){
  int len,mlen,c;
  int a;
  char num[IWIDTH(CPU_SETSIZE)+1];  // should be as wide as cpumax
  char imask[IMASK_MAXSIZE]; // try this for now worst case is 0 2 4 6 ...
  char *sep; // Used for separator between values or ranges
  
  len=strlen(mask);
  imask[0]=0;

  a=-1;

  sep = "";  
  if (mask[0]!='.') { a=0;}
  for(c=1;c<len;c++){
    //printf("%d %c\n",c,mask[c]);
    // Check if we are going between bound to cpus or not bound to cpus
    // second test is due to NUMA encoding
    if (mask[c]!=mask[c-1] &&
	((mask[c]=='.' || (mask[c-1]=='.'))) ) {
      if (mask[c]!='.'){
       // This is a cpu we are bound to
        a=c;
       } else {
	// We are not bound to a cpu
        if (a!=-1){
          sprintf(num,"%s%d",sep,a);
	  strcat(imask,num);
          if (c>(a+1)){
            sprintf(num,"-%d",c-1);
   	    strcat(imask,num);
	  }
	  sep = " ";
          a=-1;
	}
       }   

    }

  }

  c=len-1;
  if (mask[c]!='.') 
    // This is the case where the last mask value is a cpu
     if (a!=-1){
        sprintf(num,"%s%d",sep,a);
	strcat(imask,num);
        if (c>(a+1)){
          sprintf(num,"-%d",c); //This was c-1 which I think was wrong
          strcat(imask,num);
         }
      } else {
        sprintf(num,"%s%d",sep,c);
        strcat(imask,num);
     }

  *integer_mask=(char *)malloc((size_t)strlen(imask)*sizeof(char)+1);
  strcpy(*integer_mask,imask);
  //printf("imask: <%s> len %lu\n",*integer_mask,strlen(*integer_mask));

}

// The format of the mask here is either . or numeric numa node
void make_inuma_mask(char **inuma_mask,int *cpu_to_node,
		     int ncpus,int numa_nodes,
		     char *cpu_mask){
  char imask[MAX_NUMA_NODES*3]; // try this for now worst case is 0,2,4,6,8
  char num[IWIDTH(MAX_NUMA_NODES)+1];
  int *numa_counts;
  int c,k,a;
  char line[100];
  char *sep; // Used for separator between values or ranges

  numa_counts=(int *)malloc((size_t)numa_nodes*sizeof(int));
  imask[0]=0;
  for(k=0;k<numa_nodes;k++){
    numa_counts[k]=0;
   }
  for(c=0;c<strlen(cpu_mask);c++){
    if(cpu_mask[c]!='.'){
      numa_counts[cpu_to_node[c]]++;
    }
   }
  /*
  printf("numa_counts: ");
  for(k=0;k<numa_nodes;k++){
    printf(" %d",numa_counts[k]);
  }
  printf("\n");
  */
  a = -1;
  sep = "";  
  if (numa_counts[0]>0){ a=0;}
  for(k=1;k<numa_nodes;k++){
    if ((numa_counts[k]>0) != (numa_counts[k-1]>0)){
      if (numa_counts[k]>0){
        // This is a new range
        a = k;
       } else {
	// there is no binding to this numa domain
        if (a!=-1){
	  sprintf(num,"%s%d",sep,a);
	  strcat(imask,num);
	  if (k>(a+1)){
  	    sprintf(num,"-%d",k-1);
	    strcat(imask,num);
	   }
	  sep = " ";
	  a=-1;
	}
      }
    }
  }
  k=numa_nodes-1;
  if (numa_counts[k]>0){
    // The final numa domain was used
    if (a!=-1){
      sprintf(num,"%s%d",sep,a);
      strcat(imask,num);
      if (k>(a+1)){
        sprintf(num,"-%d",k);
        strcat(imask,num);
      }
    } else {
      sprintf(num,"%s%d",sep,k);
     strcat(imask,num);
    }  
  }

  // Remove any training space character
  if (imask[strlen(imask)-1]==' ') imask[strlen(imask)-1]=0; 
  *inuma_mask=(char *)malloc((size_t)strlen(imask)*sizeof(char)+1);
  strcpy(*inuma_mask,imask);
  //printf("inumamask: <%s> len %lu\n",*inuma_mask,strlen(*inuma_mask));
  
}

int main(int argc, char **argv){

  char host[MAXHOSTNAME],myhost[MAXHOSTNAME];
  char env[ENV_MAXSIZE];
  char label[LABEL_MAXSIZE];
  char mask[MASK_MAXSIZE];
  char line[100];
  cpu_binding_s b;
  int omp_tid,tid,i,k,r,len;
  int rank,size;
  int lcpu;
  hostinfo_p hostinfo,hi;
  rankinfo_p rankinfo;
  threadinfo_p ti;
  int rank_w,hname_w,thread_w,oncpu_w,tid_w,
      numa_w,count_w,place_cpu_w,label_w,gpu_info_w;
  int visible_devices_w=0;
  int maxranks,minranks,maxthreads,minthreads,nthreads,nthreads_r;  
  int process_threadcount,process_threadcount_r;
  int ranks_over_threaded; // set of we see more threads than OMP_NUM_THREADS
  int maxmasklen=0;
  int maximasklen=0;
  int maxinumamasklen=0;
  int maxpcibusidlistlen=0;
  int maxgpunumanodeslistlen=0;
  int maxcvdlen=0;
  int maxhvdlen=0;
  int maxrvdlen=0;
  int output_masklen;
  MPI_Comm mcw;
  MPI_Status mstatus;
  char *oenv,*gpu_env,compiler_info[MAXLINE];
  int ont_allsame;
  int sparsify=0;
  int order_byrank=0; 
  int show_numa=0;
  int show_oncpu=ONCPU_DEFAULT;
  int show_mask=SHOW_MASK_DEFAULT;
  int show_numeric_mask=SHOW_NUMERIC_MASK_DEFAULT;
  int report_over_threaded=REPORT_OVER_THREADED;
  int show_tid=0;
  int numa_nodes,*cpu_to_node;
  int compact=1; // Set to 1 to only print host and rank when it changes
  int ncpus;
  mask_format_e mask_format;
  int split_mask=1;
  int have_monobinding=0; // true if we 
  // temporaries
  int ibuffer[2];
  char field_temp[MAXLINE]; // Used to create short field strings 
  char busids_temp_str[MAXLINE]; // large enough for 32 3 char entries
  char gpu_numa_nodes_temp_str[MAXLINE]; // large enough for 32 3 char entries
  char *gpu_vd_h = "*VD"; // We will make this speific later
  label_w=strlen("label"); // _w variables hold field widths
  count_w=strlen("count");  // Used for the pinning column
  numa_w=strlen("NUMA");

  mask_format = FORMAT_FILLED;

  get_compiler_info(compiler_info,MAXLINE);
  gethostname(myhost,MAXHOSTNAME);

  MPI_Init(&argc, &argv);
  mcw=MPI_COMM_WORLD;
  MPI_Comm_size(mcw,&size);
  MPI_Comm_rank(mcw,&rank);
  rank_w=IWIDTH(size-1);

  if (rank==0) get_args(argc,argv,
                        &order_byrank,
                        &show_mask,&show_numeric_mask,
                        &show_numa,&split_mask,
                        &show_oncpu,&show_tid,
                        &use_label,&show_gpu,&show_gpu_envs);

  MPI_Bcast(&use_label,1,MPI_INT,0,mcw);
  MPI_Bcast(&show_numa,1,MPI_INT,0,mcw);
  MPI_Bcast(&show_gpu,1,MPI_INT,0,mcw);
  MPI_Bcast(&show_gpu_envs,1,MPI_INT,0,mcw);

  if (rank==0) {
    printf(
     "MPI and OpenMP Affinity Checker %s\n"
     "\n"
     "Built with compiler: %s\n\n",
     ACHECK_VERSION,compiler_info);
  }

  rankinfo=(rankinfo_p)malloc((size_t)size*sizeof(rankinfo_s));
  // Now get the host and rank MPI info
  hostinfo=NULL;

  if (rank!=0) {
    if (size>1) MPI_Send(myhost,strlen(myhost)+1,MPI_CHAR,0,2,mcw); 
   } else {
    hostinfo=create_hostinfo(hostinfo,myhost);
    hostinfo->ranks=(int *) malloc((size_t)sizeof(int));
    (&rankinfo[0])->hostinfo=hostinfo;
    hostinfo->nranks++;

    if (size==1) {
      hostinfo->nranks=1;
      (hostinfo->ranks)[0]=rank;
     } else {
      // We wa nt to get the hosts in rank order
      for (r=1;r<=size-1;r++){
        MPI_Recv(host,MAXHOSTNAME,MPI_CHAR,r,2,mcw,&mstatus);
        if (hostinfo==NULL) {
          hostinfo=create_hostinfo(hostinfo,host);
          hi=hostinfo;
         } else {
          hi=create_hostinfo(hostinfo,host);
         }
         hi->nranks++;
         rankinfo[r].hostinfo=hi;
       }
    }
  }

  if (rank==0) {

    // Fix up the rank lists and maxima minima
    minranks=size;
    maxranks=1;
    hname_w=1;
    hi=hostinfo;
    do {
      hname_w = max( hname_w, strlen(hi->name) );
      minranks = min( minranks, hi->nranks );     
      maxranks = max( maxranks, hi->nranks );     
      hi->ranks=(int *)malloc((size_t)hi->nranks*sizeof(int));
      hi->nranks=0;
      hi=hi->next;
     } while (hi!=NULL);
    for(r=0;r<size;r++){
      hi=rankinfo[r].hostinfo;
      hi->ranks[hi->nranks++]=r;
    }

    // Now print what we have

    if (size==1) {
      printf("There is one MPI rank running on host %s\n",rankinfo[0].hostinfo->name);
     } else if (!verbose) {
        printf("There are %d MPI Processes on %d hosts",size,nhosts);
        if (minranks!=maxranks) {
          printf("\n  the number of ranks per host varied between %d and %d\n\n",
                 minranks,maxranks);
         } else {
          printf(" with %d ranks per host\n",maxranks);
         }
       } else {
        printf("There are %d MPI Processes on %d hosts\n",size,nhosts);
        print_hostmap(hostinfo,rankinfo,size,rank_w,hname_w);
       }

  } // rank 0

  MPI_Barrier(mcw);

  nthreads = 0;

  if (use_label){
    if (!(rankinfo[rank].label=getenv("ACHECK_LABEL"))){
      rankinfo[rank].label = argv[0];
      }
  }


  // Just in case omp_get_num_threads () is broken
#pragma omp parallel
  {
#pragma omp atomic
    nthreads++;
  }

  process_threadcount = get_process_threadcount();

  oenv = getenv("OMP_NUM_THREADS");
  rankinfo[rank].nthreads=nthreads;
  rankinfo[rank].process_threadcount=process_threadcount;
  if (oenv==NULL){
    rankinfo[rank].env_ont = "undefined"; // this has to match the string later
   } else {
    rankinfo[rank].env_ont = oenv;
   }
  rankinfo[rank].threadinfo=(threadinfo_p)malloc(
      (size_t)nthreads*sizeof(rankinfo_s));


  ncpus = getnumcpus();
  if (show_numa) {
    cpu_to_node=(int *)malloc((size_t)ncpus*sizeof(int));
    numa_nodes=get_numa_map(cpu_to_node,ncpus,ncpus);
    if (numa_nodes==0) show_numa=0;

  }
  // now get binding
  if (mask_format == FORMAT_FILLED) {
    if (ncpus==0) mask_format=FORMAT_DEFAULT;
  }


#pragma omp parallel private(omp_tid,lcpu,b) shared(rankinfo,maxmasklen,maximasklen,maxinumamasklen,count_w)
 {
   omp_tid=omp_get_thread_num();
#pragma omp critical
   {
     lcpu=getlastcpu();
   }
   getaffinity(&b,mask_format,ncpus,show_numa,cpu_to_node);
   make_imask(&(b.integer_mask),b.mask);
   ti=rankinfo[rank].threadinfo;
   ti[omp_tid].omp_tid=omp_tid; 
#ifdef USE_GETTID
   ti[omp_tid].tid = (int)gettid();
#endif
   ti[omp_tid].binding.cpu=lcpu;
   ti[omp_tid].binding.ncpu=b.ncpu;
   ti[omp_tid].binding.mask=b.mask;
   ti[omp_tid].binding.integer_mask=b.integer_mask;
   if (show_numa){
    make_inuma_mask(&(ti[omp_tid].binding.integer_numa_mask),
		    cpu_to_node,ncpus,numa_nodes,b.mask);
    // printf("rank %d tid %d imask=%s\n",rank,omp_tid,ti[omp_tid].binding.numa_mask);
   }

#pragma omp critical
   {
     maxmasklen = max ( maxmasklen, strlen(b.mask) );
     maximasklen = max ( maximasklen, strlen(b.integer_mask) );
     if (show_numa){
       maxinumamasklen = max ( maxinumamasklen,
			       strlen(ti[omp_tid].binding.integer_numa_mask) );
      }
     if (b.ncpu > 1){ count_w = max(count_w,IWIDTH(b.ncpu)+strlen(" cpus"));}
   }

 }

#if ACCEL_SUPPORT_ROCR
  {
  int num_devices=0;
  char busid[64],busid_copy[64];
  char gpu_numa_node[64],gpu_numa_nodes[64];
  char *pciid;
  hipError_t herr;
  int len;

  busids_temp_str[0]=0;
  gpu_numa_nodes_temp_str[0]=0;
  herr=hipGetDeviceCount(&num_devices);
  if (herr!=hipSuccess){ num_devices=-1;}
   for(int i=0; i<num_devices; i++){
     hipSetDevice(i);
     hipDeviceGetPCIBusId(busid, 64, i);
     strncpy(busid_copy,busid,64);
     strtok(busid_copy,":");
     pciid=strtok(NULL,":");
     if (busids_temp_str[0]!=0){
       len=strlen(busids_temp_str);
       busids_temp_str[len]=',';
       busids_temp_str[len+1]=0;
      } 
     strcat(busids_temp_str,pciid);
     if (show_numa){
       if (get_gpu_numa_node(gpu_numa_node,busid)==EXIT_SUCCESS){
         //printf("pciid %s numa %s\n",busid,gpu_numa_node);
	 if (gpu_numa_nodes_temp_str[0]!=0){
	   len = strlen(gpu_numa_nodes_temp_str);
	   gpu_numa_nodes_temp_str[len]=',';
	   gpu_numa_nodes_temp_str[len+1]=0;
	  }
	 strcat(gpu_numa_nodes_temp_str,gpu_numa_node);
       }
     }
   }
   rankinfo[rank].gpuinfo.HIP_pcibusidlist=(char *)malloc((size_t)strlen(busids_temp_str)+1);
   strcpy(rankinfo[rank].gpuinfo.HIP_pcibusidlist,busids_temp_str);
   maxpcibusidlistlen=max(maxpcibusidlistlen,strlen(busids_temp_str));
   if (show_numa){
     rankinfo[rank].gpuinfo.numa_nodelist=(char *)malloc((size_t)strlen(gpu_numa_nodes_temp_str)+1);
     strcpy(rankinfo[rank].gpuinfo.numa_nodelist,gpu_numa_nodes_temp_str);
     maxgpunumanodeslistlen=max(maxgpunumanodeslistlen,strlen(gpu_numa_nodes_temp_str));
     //printf("numa nodes %s\n",rankinfo[rank].gpuinfo.numa_nodelist);
    }
   // Now envars that might affect GPU selection
   gpu_env = getenv("CUDA_VISIBLE_DEVICES");
   if (gpu_env==NULL){
     rankinfo[rank].gpuinfo.env_cuda_visible_devices = "undefined";
    } else {
     rankinfo[rank].gpuinfo.env_cuda_visible_devices = gpu_env;
     maxcvdlen = max(maxcvdlen, strlen(gpu_env));
    }
   gpu_env = getenv("HIP_VISIBLE_DEVICES");
   if (gpu_env==NULL){
     rankinfo[rank].gpuinfo.env_hip_visible_devices = "undefined"; 
    } else {
     rankinfo[rank].gpuinfo.env_hip_visible_devices = gpu_env;
     maxhvdlen = max(maxhvdlen, strlen(gpu_env));
    }
   gpu_env = getenv("ROCR_VISIBLE_DEVICES");
   if (gpu_env==NULL){
     rankinfo[rank].gpuinfo.env_rocr_visible_devices = "undefined"; 
    } else {
     rankinfo[rank].gpuinfo.env_rocr_visible_devices = gpu_env;
     maxrvdlen = max(maxrvdlen, strlen(gpu_env));
    }
   
  }
#endif

 
 // communicate thread information to rank 0
 minthreads=nthreads;
 maxthreads=nthreads;

 if (process_threadcount > nthreads) {
   ranks_over_threaded = 1;
  } else {
   ranks_over_threaded = 0;
  }
 MPI_Barrier(mcw);
 if (rank!=0) {
   if (size>1) {
     // ---- nthreads
     ibuffer[0] = nthreads;
     ibuffer[1] = process_threadcount;
     MPI_Send(ibuffer,2,MPI_INT,0,3,mcw); 
     // ---- OMP_NUM_THREADS
     if (oenv==NULL) {
       MPI_Send("undefined",strlen("undefined")+1,MPI_CHAR,0,4,mcw);
      } else {
       MPI_Send(oenv,strlen(oenv)+1,MPI_CHAR,0,4,mcw);
      }
     // --- labels
     if (use_label){
       MPI_Send(rankinfo[rank].label,strlen(rankinfo[rank].label)+1,
                MPI_CHAR,0,44,mcw);
      }
#if ACCEL_SUPPORT_ROCR
       if (show_gpu){
         MPI_Send(rankinfo[rank].gpuinfo.HIP_pcibusidlist,
		  strlen(rankinfo[rank].gpuinfo.HIP_pcibusidlist)+1,
		  MPI_CHAR,0,45,mcw);
	 if (show_numa){
           MPI_Send(rankinfo[rank].gpuinfo.numa_nodelist,
		   strlen(rankinfo[rank].gpuinfo.numa_nodelist)+1,
		   MPI_CHAR,0,46,mcw);

	  }
	 if (show_gpu_envs){
           MPI_Send(rankinfo[rank].gpuinfo.env_cuda_visible_devices,
		   strlen(rankinfo[rank].gpuinfo.env_cuda_visible_devices)+1,
		   MPI_CHAR,0,47,mcw);
           MPI_Send(rankinfo[rank].gpuinfo.env_hip_visible_devices,
		   strlen(rankinfo[rank].gpuinfo.env_hip_visible_devices)+1,
		   MPI_CHAR,0,48,mcw);
           MPI_Send(rankinfo[rank].gpuinfo.env_rocr_visible_devices,
		   strlen(rankinfo[rank].gpuinfo.env_rocr_visible_devices)+1,
		   MPI_CHAR,0,49,mcw);
         }
       }
#endif
     // --- binding data
     ti=rankinfo[rank].threadinfo;
     for(omp_tid=0;omp_tid<rankinfo[rank].nthreads;omp_tid++){
       MPI_Send(&(ti[omp_tid].omp_tid),1,MPI_INT,0,5,mcw);
#ifdef USE_GETTID
       MPI_Send(&(ti[omp_tid].tid),1,MPI_INT,0,5,mcw);
#endif
       MPI_Send(&(ti[omp_tid].binding.cpu),1,MPI_INT,0,5,mcw);
       MPI_Send(&(ti[omp_tid].binding.ncpu),1,MPI_INT,0,5,mcw);
       MPI_Send(ti[omp_tid].binding.mask,
                strlen(ti[omp_tid].binding.mask)+1,MPI_CHAR,0,5,mcw);
       if (show_numa){
         MPI_Send(ti[omp_tid].binding.integer_numa_mask,
                  strlen(ti[omp_tid].binding.integer_numa_mask)+1,
		  MPI_CHAR,0,6,mcw);
	 
       }
      }
    }
  } else {
   // ---- nthreads
   for (r=1;r<=size-1;r++){
     MPI_Recv(&ibuffer,2,MPI_INT,MPI_ANY_SOURCE,3,mcw,&mstatus);
     nthreads_r = ibuffer[0];
     process_threadcount_r = ibuffer[1];
     rankinfo[mstatus.MPI_SOURCE].nthreads=nthreads_r;
     minthreads = min (nthreads_r, minthreads);
     maxthreads = max (nthreads_r, maxthreads);
     rankinfo[mstatus.MPI_SOURCE].process_threadcount=process_threadcount_r;
     if (process_threadcount_r > nthreads_r) ranks_over_threaded++;
   }
   // ---- OMP_NUM_THREADS
   for (r=1;r<=size-1;r++){
     MPI_Recv(env,ENV_MAXSIZE,MPI_CHAR,MPI_ANY_SOURCE,4,mcw,&mstatus);
     MPI_Get_count(&mstatus,MPI_CHAR,&len);
     rankinfo[mstatus.MPI_SOURCE].env_ont=(char *)malloc((size_t)len*sizeof(char));
     strcpy(rankinfo[mstatus.MPI_SOURCE].env_ont,env);
    }

   // ---- labels
   if (use_label){
     for (r=1;r<=size-1;r++){
       MPI_Recv(label,LABEL_MAXSIZE,MPI_CHAR,MPI_ANY_SOURCE,44,mcw,&mstatus);
       MPI_Get_count(&mstatus,MPI_CHAR,&len);
       rankinfo[mstatus.MPI_SOURCE].label=(char *)malloc((size_t)len*sizeof(char));
       label_w=max(label_w,len-1);
       strcpy(rankinfo[mstatus.MPI_SOURCE].label,label);
      }
    }
#if ACCEL_SUPPORT_ROCR
   if (show_gpu){
     for (r=1;r<=size-1;r++){
       MPI_Recv(busids_temp_str,MAXLINE,MPI_CHAR,MPI_ANY_SOURCE,45,mcw,
  	        &mstatus);
       MPI_Get_count(&mstatus,MPI_CHAR,&len);
       rankinfo[mstatus.MPI_SOURCE].gpuinfo.HIP_pcibusidlist = (char *)malloc((size_t)len*sizeof(char));
       strcpy(rankinfo[mstatus.MPI_SOURCE].gpuinfo.HIP_pcibusidlist,busids_temp_str);
       maxpcibusidlistlen = max(maxpcibusidlistlen, len-1);
       //printf("from rank %d string max %d, <%s>\n",mstatus.MPI_SOURCE,maxpcibusidlistlen,rankinfo[mstatus.MPI_SOURCE].gpuinfo.HIP_pcibusidlist);
       if (show_numa){
         MPI_Recv(gpu_numa_nodes_temp_str,MAXLINE,MPI_CHAR,MPI_ANY_SOURCE,46,
		  mcw,&mstatus);
         MPI_Get_count(&mstatus,MPI_CHAR,&len);
         rankinfo[mstatus.MPI_SOURCE].gpuinfo.numa_nodelist = (char *)malloc((size_t)len*sizeof(char));
         strcpy(rankinfo[mstatus.MPI_SOURCE].gpuinfo.numa_nodelist,
	        gpu_numa_nodes_temp_str);
         maxgpunumanodeslistlen = max(maxgpunumanodeslistlen, len-1);
	 //printf("from rank %d len %d <%s>\n",r,maxgpunumanodeslistlen,rankinfo[mstatus.MPI_SOURCE].gpuinfo.numa_nodelist);
        }
       if (show_gpu_envs){
	 // CUDA_VISIBLE_DEVICES
         MPI_Recv(env,ENV_MAXSIZE,MPI_CHAR,MPI_ANY_SOURCE,47,
		  mcw,&mstatus);
         MPI_Get_count(&mstatus,MPI_CHAR,&len);
         rankinfo[mstatus.MPI_SOURCE].gpuinfo.env_cuda_visible_devices = (char *)malloc((size_t)len*sizeof(char));
         strcpy(rankinfo[mstatus.MPI_SOURCE].gpuinfo.env_cuda_visible_devices,
	        env);
         if (strcmp(env,"undefined")) maxcvdlen = max(maxcvdlen, len-1);
	 //printf("from rank %d C len %d <%s>\n",r,maxcvdlen,rankinfo[mstatus.MPI_SOURCE].gpuinfo.env_cuda_visible_devices);
	 // HIP_VISIBLE_DEVICES
         MPI_Recv(env,ENV_MAXSIZE,MPI_CHAR,MPI_ANY_SOURCE,48,
		  mcw,&mstatus);
         MPI_Get_count(&mstatus,MPI_CHAR,&len);
         rankinfo[mstatus.MPI_SOURCE].gpuinfo.env_hip_visible_devices = (char *)malloc((size_t)len*sizeof(char));
         strcpy(rankinfo[mstatus.MPI_SOURCE].gpuinfo.env_hip_visible_devices,
	        env);
         if (strcmp(env,"undefined")) maxhvdlen = max(maxhvdlen, len-1);
	 //printf("from rank %d H len %d <%s>\n",r,maxhvdlen,rankinfo[mstatus.MPI_SOURCE].gpuinfo.env_hip_visible_devices);
	 // ROCR_VISIBLE_DEVICES
         MPI_Recv(env,ENV_MAXSIZE,MPI_CHAR,MPI_ANY_SOURCE,49,
		  mcw,&mstatus);
         MPI_Get_count(&mstatus,MPI_CHAR,&len);
         rankinfo[mstatus.MPI_SOURCE].gpuinfo.env_rocr_visible_devices = (char *)malloc((size_t)len*sizeof(char));
         strcpy(rankinfo[mstatus.MPI_SOURCE].gpuinfo.env_rocr_visible_devices,
	        env);
         if (strcmp(env,"undefined")) maxrvdlen = max(maxrvdlen, len-1);
	 //printf("from rank %d R len %d <%s>\n",r,maxrvdlen,rankinfo[mstatus.MPI_SOURCE].gpuinfo.env_rocr_visible_devices);

       }
      }
    }
#endif
   
   // --- binding data
   for (r=1;r<=size-1;r++){
     //     printf("rank %d allocating space for %d threads from rank %d\n",
     //	    rank,rankinfo[r].nthreads,r);
     rankinfo[r].threadinfo=(threadinfo_p)malloc(
		  (size_t)rankinfo[r].nthreads*sizeof(threadinfo_s));
     ti=rankinfo[r].threadinfo;
     for(omp_tid=0;omp_tid<rankinfo[r].nthreads;omp_tid++){
       MPI_Recv(&(ti[omp_tid].omp_tid),1,MPI_INT,r,5,mcw,&mstatus);
#ifdef USE_GETTID
       MPI_Recv(&(ti[omp_tid].tid),1,MPI_INT,r,5,mcw,&mstatus);
#endif
       MPI_Recv(&(ti[omp_tid].binding.cpu),1,MPI_INT,r,5,mcw,&mstatus);
       MPI_Recv(&(ti[omp_tid].binding.ncpu),1,MPI_INT,r,5,mcw,&mstatus);
       if (ti[omp_tid].binding.ncpu > 1){
         count_w = max(count_w,IWIDTH(ti[omp_tid].binding.ncpu)+strlen(" cpus")) ;
       }
       MPI_Recv(mask,MASK_MAXSIZE,MPI_CHAR,r,5,mcw,&mstatus);
       MPI_Get_count(&mstatus,MPI_CHAR,&len);
       maxmasklen = max(maxmasklen,len-1); // remember trailing 0
       ti[omp_tid].binding.mask=(char *)malloc((size_t)len*sizeof(char));
       strcpy(ti[omp_tid].binding.mask,mask);
       //       printf("rank %d got data for thread %d from rank %d\n",
       //	    rank,omp_tid,r);

       // at the moment we are making this again here although we could
       // have communicated it from the remote rank
       make_imask(&(ti[omp_tid].binding.integer_mask),mask);
       maximasklen = max(maximasklen,
                         strlen(ti[omp_tid].binding.integer_mask));

       // printf("%s MASK \n",ti[omp_tid].binding.integer_mask);
       if (show_numa) {
         MPI_Recv(mask,MASK_MAXSIZE,MPI_CHAR,r,6,mcw,&mstatus);
         MPI_Get_count(&mstatus,MPI_CHAR,&len);
         maxinumamasklen = max(maxinumamasklen,len-1); // remember trailing 0
         ti[omp_tid].binding.integer_numa_mask=(char *)malloc((size_t)len*sizeof(char));
         strcpy(ti[omp_tid].binding.integer_numa_mask,mask);
	 //printf("from rank %d thread %d inuma_mask <%s>\n",r,omp_tid,mask);
       }

      }
   }
  }

 if (rank==0) {
   // check consistency of OMP_NUM_THREADS
   ont_allsame=1;
   for(r=1;r<size;r++){
     if(strcmp(rankinfo[0].env_ont,rankinfo[r].env_ont)!=0)ont_allsame=0;
   }
   if (minthreads==maxthreads) {
     if (size>1){
       printf("Each MPI process has %d OpenMP threads\n",maxthreads);
      } else {
       printf("There are %d OpenMP threads\n",maxthreads);
      }
   } else {
     printf("Each MPI process has a number of OpenMP threads varying from %d to %d\n",minthreads,maxthreads);
   }
   if (ont_allsame==1){
     printf("OMP_NUM_THREADS was set to %s\n",rankinfo[0].env_ont);
    } else {
     printf("OMP_NUM_THREADS varied per process (set to %s on rank 0)\n",rankinfo[0].env_ont);
    }
   if (show_gpu_envs){
     if (maxcvdlen+maxhvdlen+maxrvdlen > 0){
       printf("The following GPU selection envars have been set:\n  ");
       if (maxcvdlen>0)printf(" CUDA_VISIBLE_DEVICES");
       if (maxhvdlen>0)printf(" HIP_VISIBLE_DEVICES");
       if (maxrvdlen>0)printf(" ROCR_VISIBLE_DEVICES");
     }
     printf("\n");
     if (maxcvdlen > 0){
       visible_devices_w = maxcvdlen;
       gpu_vd_h = "CVD";
      } else if (maxhvdlen > 0 ){
       visible_devices_w = maxhvdlen;
       gpu_vd_h = "HVD";
      } else if (maxrvdlen > 0 ) {
       visible_devices_w = maxrvdlen;
       gpu_vd_h = "RVD";
      }
   }
   // This is conplicated.  The APLS startup gives one more thread to the
   // first process on a node if you use more than one nodes.
   if ( report_over_threaded &&
        (nhosts==1 && ranks_over_threaded >0) || 
        (nhosts>1 && ranks_over_threaded > nhosts)) {
     if (size>1){
       printf("WARNING: %d ranks had more threads per process than OpenMP threads\n",ranks_over_threaded);
     } else {
       printf("WARNING: There are more threads than OpenMP threads\n");
     }

   }
 }

 rank_w=max(rank_w,strlen("rank"));
 thread_w=strlen("thr");
 if (show_oncpu){
   oncpu_w=strlen("on-cpu");
  } else {
   oncpu_w=0;
  }
 if (show_tid){
   tid_w=strlen("OStid");
  } else {
   tid_w=0;
  }
#if ACCEL_SUPPORT_ROCR
 if (show_gpu){
   maxpcibusidlistlen = max(maxpcibusidlistlen,strlen("busid"));
   maxgpunumanodeslistlen = max(maxgpunumanodeslistlen,strlen("NUMA"));
   visible_devices_w = max(visible_devices_w,strlen(gpu_vd_h));
 }
#endif
 if (show_numa){
   numa_w = max( numa_w, maxinumamasklen );
  }
 place_cpu_w=2; // not using yet

 if (split_mask != 1 ){
   output_masklen = maxmasklen / split_mask ; 
  } else {
   output_masklen = maxmasklen;
  }

 // Now do it all from rank 0
   if (rank==0 && verbose) {

     // We start by first header line using fake printfs to get correct indents
     len=count_w+strlen("mask")+1-strlen("binding---");
     if (use_label) printf(" %*s",label_w,"");
     printf("\n");
     printf(" %*s %*s",hname_w,"",rank_w,"");
     //     printf(" %*s %*s %*s %s",thread_w,"",tid_w,"",oncpu_w,"","---binding");
     printf(" %*s  ",thread_w,"");
     if (show_tid)
       printf("%*s ",tid_w,"");
#if ACCEL_SUPPORT_ROCR
     if (show_gpu){
       gpu_info_w = maxpcibusidlistlen;
       if (show_numa || (visible_devices_w>0)){
         if (visible_devices_w > 0) gpu_info_w+=visible_devices_w+1;
         if (show_numa) gpu_info_w += maxgpunumanodeslistlen+1;
         //printf("%-*s ",gpu_info_w,"-GPU info");
	 printf("-GPU info");
	 k = gpu_info_w - strlen("-GPU info");
	 if (k>0) for(i=0;i<k;i++)printf("-");
         printf(" ");
        } else {
         printf("%-*s ",gpu_info_w,"-GPU-");
        }
     }
#endif
     if (show_oncpu)
       printf("%*s ",oncpu_w,"");
     if (show_numa){
       printf("%*s ",numa_w,"");
      }
     printf("%s","-binding--");

     k=max(output_masklen-len,len);  // double check this
     // old -- if (!show_mask) k=max(maximasklen-len,len);
     if (!show_mask) k=max(maximasklen-strlen("mask")+len,len);
     if (k>0) for(i=0;i<k;i++)printf("-");
     printf("\n");
     printf(" %*s %*s",hname_w,"host",rank_w,"rank");
     if (use_label) printf(" %*s",label_w,"label");
     //     printf(" %*s %.*s %.*s %*s %s\n",thread_w,"thr",tid_w,"OStid",oncpu_w,"on-cpu",count_w,"pinning","mask");
     printf(" %*s  ",thread_w,"thr");
     if (show_tid) printf("%.*s ",tid_w,"OStid");
#if ACCEL_SUPPORT_ROCR
     if (show_gpu){
       if (visible_devices_w > 0) {
        printf("%-*s ",visible_devices_w,gpu_vd_h);
       }
       printf("%-*s ",maxpcibusidlistlen,"busid");
       if (show_numa){
         printf("%-*s ",maxgpunumanodeslistlen,"NUMA");
        }
     }
#endif
     if (show_oncpu) printf("%.*s ",oncpu_w,"on-cpu");
     if (show_numa) printf("%-*s ",numa_w,"NUMA");
     printf("%-*s %s\n",count_w,"count","mask");
     { char *lasthost;
       int lastrank;
       int mindent;
    
       mindent=1+hname_w+1+rank_w+1+thread_w+2+count_w+1;
       if (show_oncpu){ mindent+=oncpu_w+1;}
       if (show_tid){ mindent+=tid_w+1;}
       if (order_byrank) {
         // Ordered by rank

         lasthost="";
         lastrank=MPI_PROC_NULL;
         for(r=0;r<size;r++){
           ti=rankinfo[r].threadinfo;
           for(omp_tid=0;omp_tid<rankinfo[r].nthreads;omp_tid++){
             if (!compact || strcmp(lasthost,rankinfo[r].hostinfo->name)!=0){
               printf(" %*s",hname_w,rankinfo[r].hostinfo->name);
               lasthost=rankinfo[r].hostinfo->name;
    	      } else {
               printf(" %*s",hname_w,"");
	      }
             if (!compact || lastrank!=r){
               printf(" %*d",rank_w,r);
               lastrank=r;
	      } else {
               printf(" %*s",rank_w,"");
	      }
             if (use_label){
	       printf(" %*s",label_w,rankinfo[r].label);
	     }
             printf(" %*d  ",thread_w,omp_tid);
             if (show_tid){
               printf("%*d ",tid_w,ti[omp_tid].tid);
	     }
#if ACCEL_SUPPORT_ROCR
	     // Only do this if omp_tid>0 but need to fix whitespace
             if (show_gpu ){
	       if (omp_tid<1){
		 if (visible_devices_w > 0){
  		   char *vdenv=NULL;
                   if (maxcvdlen > 0){
                     vdenv = rankinfo[r].gpuinfo.env_cuda_visible_devices;
                    } else if (maxhvdlen > 0 ){
                    vdenv = rankinfo[r].gpuinfo.env_hip_visible_devices;
                    } else if (maxrvdlen > 0 ) {
                     vdenv = rankinfo[r].gpuinfo.env_rocr_visible_devices;
                    }
		   if (vdenv!=NULL && strcmp(vdenv,"undefined")){
		      printf("%-*s ",visible_devices_w,vdenv);
		    } else {
		     printf("%-*s ",visible_devices_w,"");
		    }
		   }
                  printf("%-*s ",maxpcibusidlistlen,rankinfo[r].gpuinfo.HIP_pcibusidlist);
	          if (show_numa){
	            printf("%-*s ",maxgpunumanodeslistlen,rankinfo[r].gpuinfo.numa_nodelist);
       	          }
	       } else {
	       // space this would have taken up
	       printf("%*s ",gpu_info_w,"");
	       }
	      }
#endif
             if (show_oncpu) {
               printf("%*d ",oncpu_w,ti[omp_tid].binding.cpu);
	      }
             if (show_numa){
	       printf("%-*s ",numa_w,ti[omp_tid].binding.integer_numa_mask);
	      }
             if (ti[omp_tid].binding.ncpu >1){
	       sprintf(field_temp,"%d cpus",ti[omp_tid].binding.ncpu);
               printf("%-*s",count_w,field_temp);
              } else {
	       //               printf("cpu %3d",ti[omp_tid].binding.cpu);
               printf("%-*s",count_w,"1 cpu");
              }
	     if (show_numa){
	       printf("%-*s ",numa_w,ti[omp_tid].binding.integer_numa_mask);
	      }
             if (show_mask)
             if (split_mask !=0 ) {
               printf(" %.*s\n",
		      output_masklen,ti[omp_tid].binding.mask);
               for(int k=1;k<split_mask;k++){
                 printf("%*s%.*s\n",
			mindent," ",output_masklen,&(ti[omp_tid].binding.mask[k*output_masklen]));
	       }
 	      } else {
               printf(" %s\n",ti[omp_tid].binding.mask);
	      }
             // the show_mask here is in case we just drew one
             if (show_numeric_mask)
	     if (show_mask){
	       printf("%*s%s\n",
                   mindent," ",ti[omp_tid].binding.integer_mask);
	      } else {
	       printf(" %s\n",
                   ti[omp_tid].binding.integer_mask);
	      }
           } /* for omp_tid */
         }

       } else {

	// order by host
        lasthost="";
        lastrank=MPI_PROC_NULL;
        hi=hostinfo;
        do {

          for(k=0;k<hi->nranks;k++){
            r=hi->ranks[k];
            ti=rankinfo[r].threadinfo;
            for(omp_tid=0;omp_tid<rankinfo[r].nthreads;omp_tid++){
              if (!compact || strcmp(lasthost,rankinfo[r].hostinfo->name)!=0){
                printf(" %*s",hname_w,rankinfo[r].hostinfo->name);
                lasthost=rankinfo[r].hostinfo->name;
    	       } else {
                printf(" %*s",hname_w,"");
	       }
              if (!compact || lastrank!=r){
                printf(" %*d",rank_w,r);
                lastrank=r;
	       } else {
                printf(" %*s",rank_w,"");
	       }
              if (use_label){
	        printf(" %*s",label_w,rankinfo[r].label);
	      }
              printf(" %*d  ",thread_w,omp_tid);
              if (show_tid){
                printf("%*d ",tid_w,ti[omp_tid].tid);
	       }
#if ACCEL_SUPPORT_ROCR
	      // Only do this if omp_tid>0 but need to fix whitespace
              if (show_gpu ){
	        if (omp_tid<1){
		  if (visible_devices_w > 0){
  		    char *vdenv=NULL;
                    if (maxcvdlen > 0){
                      vdenv = rankinfo[r].gpuinfo.env_cuda_visible_devices;
                     } else if (maxhvdlen > 0 ){
                      vdenv = rankinfo[r].gpuinfo.env_hip_visible_devices;
                     } else if (maxrvdlen > 0 ) {
                      vdenv = rankinfo[r].gpuinfo.env_rocr_visible_devices;
                     }
		    if (vdenv!=NULL && strcmp(vdenv,"undefined")){
		        printf("%-*s ",visible_devices_w,vdenv);
		     } else {
		      printf("%-*s ",visible_devices_w,"");
		     }
		    }
                   printf("%-*s ",maxpcibusidlistlen,rankinfo[r].gpuinfo.HIP_pcibusidlist);
		   if (show_numa){
		     printf("%-*s ",maxgpunumanodeslistlen,rankinfo[r].gpuinfo.numa_nodelist);
		   }
		} else {
		// space this would have taken up
		printf("%*s ",gpu_info_w,"");
		}
	      }
#endif
              if (show_oncpu) {
                printf("%*d ",oncpu_w,ti[omp_tid].binding.cpu);
	       }
              if (show_numa){
	        printf("%-*s ",numa_w,ti[omp_tid].binding.integer_numa_mask);
	       }
              if (ti[omp_tid].binding.ncpu >1){
		sprintf(field_temp,"%d cpus",ti[omp_tid].binding.ncpu);
                printf("%-*s",count_w,field_temp);
               } else {
		//                printf("cpu %3d",ti[omp_tid].binding.cpu);
                printf("%-*s",count_w,"1 cpu");
               }
              if (show_mask)
              if (split_mask!=0) {
                printf(" %.*s\n",
		      output_masklen,ti[omp_tid].binding.mask);
                for(int k=1;k<split_mask;k++){
                   printf("%*s%.*s\n",
		       mindent," ",output_masklen,&(ti[omp_tid].binding.mask[k*output_masklen]));
	        }
 	       } else {
                printf(" %s\n",ti[omp_tid].binding.mask);
	       }
              // the show mask here is in case we just drew one
              if (show_numeric_mask)
	      if (show_mask){
	        printf("%*s%s\n",
                    mindent," ",ti[omp_tid].binding.integer_mask);
	       } else {
	        printf(" %s\n",
                    ti[omp_tid].binding.integer_mask);
	       }

            } /* for omp_tid */
	  }
          hi=hi->next;
	 } while (hi!=NULL);

       }



     printf("\n");

     }

   } /* rank 0 verbose */

  MPI_Finalize();

  return EXIT_SUCCESS;

}
