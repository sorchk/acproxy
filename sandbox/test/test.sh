docker run -it --rm \
-v /opt/docker:/opt/docker \
-v /var/run/docker.sock:/var/run/docker.sock \
sorc/sandbox-node:24.04 /bin/bash
