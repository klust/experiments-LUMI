# AI Bootcamp on Leonardo

@**EuroHPC Summit** 2024  
18-21 March 2024 in Antwerp, Belgium

https://www.eurohpcsummit.eu

The EuroHPC Summit 2024 will bring together relevant European supercomputing stakeholders, public and private, as well as decision makers, allowing them to share the latest technological developments, define synergies, express their current and future needs, and participate in shaping the future of European supercomputing.

## Download/Clone repository

```bash
git clone https://gitlab.hpc.cineca.it/cineca-ai/bootcamp-ai-leonardo.git
```


## Hands-on Sessions

Hands on sessions will be held on **Leonardo** cluster at CINECA.  
For a detailed guide on Leonardo cluster see
[here](https://wiki.u-gov.it/confluence/display/SCAIUS/UG3.2%3A+LEONARDO+UserGuide) and on Booster Module see 
[here](https://wiki.u-gov.it/confluence/display/SCAIUS/UG3.2.1%3A+LEONARDO+Booster+UserGuide).

In order to login on Leonardo cluster for the hands-on sessions
a valid username and password are provided during the lesson.

We have reserved userid from a08tra16 to a08tra20 and from a08tra65 to a08tra89 for this bootcamp.

You can connect to a Leonardo login node using SSH connection:
```
ssh a08traXX@login.leonardo.cineca.it
```
where XX is in the range {16, ... , 20, 65, ... , 89} and it is the username assigned to you.

Please complete and compile the exercises on **login node**.  
Once you have completed the exercise you can request a GPU resource on a **compute node** to run it.


## Load Environment Modules

You can load and set your environment through module:
```bash
module load profile/candidate cineca-ai/4.3.0
```
This will set all environment variables (PATH and LD_LIBRARY_PATH) to the CINECA-AI environment which will provide you with most used AI packages and tools for the hands-on sessions.

You can also load, list, inspect or purge the current state of loaded modules through the followin commands:
```bash
module avail # show the full list of available modules
module list # list currently loaded modules
module show <modulename> # inspect setup of a module
module purge # completely unload all loaded modules
```

### On Leonardo

To open a notebook directly on a compute node a double ssh tunnel is required following the steps below:


1. On `localhost` (your laptop) open an ssh session to `leonardo` login node (i.e: `login01-ext.leonardo.cineca.it`)
from the shell (for Windows users use [Putty](https://www.putty.org/)) with the command:

```bash
ssh USERNAME@login01-ext.leonardo.cineca.it 
```
All of you has already received a personal USERNAME (`a08traXY`) and a password.

Once you are on `leonardo` login, submit an interactive job to get a compute node:

```bash
srun -N 1 --ntasks-per-node=4 --cpus-per-task=8 --gres=gpu:4 -A EUHPC_T_Boot-AI -p boost_usr_prod --reservation s_tra_bootAI -t 02:00:00 --exclusive --pty /bin/bash
```
The name of compute node will appear on the prompt once you got it (i.e.: `lrdn1342`):

```bash
USERNAME@lrdnXXXX
```

More details can be found in
[`leonardo` user guide](https://wiki.u-gov.it/confluence/display/SCAIUS/UG3.2%3A+LEONARDO+UserGuide).


2. On another shell from your local machine open a ssh tunnel to login node and from login node to compute node:

```bash
ssh -L 9999:localhost:9999 USERNAME@login01-ext.leonardo.cineca.it ssh -L 9999:localhost:9999 -N lrdnXXXX
```


3. Go back to the shell on the remote host (`leonardo`) and open the jupyter notebook on the selected port with the following command:

```bash
jupyter notebook --port=9999 --no-browser
```


4. To access the notebook, open a browser on `localhost` and copy and paste the URL that will appear on the shell after you have lanched jupyter.

```bash
http://localhost:9999/?token=75f9c6d4611a636b3249cd79fe10b218ab1f1c267d4c53d13
```
