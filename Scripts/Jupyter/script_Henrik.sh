export CONFIG_FILE="${PWD}/config.py"
cat > "${CONFIG_FILE}" << EOL
c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False
c.NotebookApp.allow_origin = '*'
c.NotebookApp.notebook_dir = '$PWD'
c.NotebookApp.disable_check_xsrf = True
c.NotebookApp.allow_remote_access = True
EOL

jupyter notebook --config=config.py &>/dev/null &
pid=$!

# find url with token and port for ssh forwarding
# the while loop ensures that the server has been started
url=""
while [ -z "$url" ]
do
    sleep 3
    url=`jupyter notebook list | sed -n 's/\(http.*\) ::.*/\1/p'`
done

port=`echo $url | sed -e 's/.*host:\([0-9]*\).*/\1/'`
