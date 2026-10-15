# cd to location of script file
cd "$(dirname "$0")"

# set permissions and user and group
sudo chown -R root:docker .
sudo chmod -R 777 .
# sudo chmod -R 777 /usr/share/dotnet

echo $(date -u +"%Y-%m-%dT%H:%M:%SZ")
