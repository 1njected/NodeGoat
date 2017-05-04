FROM       ubuntu:latest

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
RUN apt-get install -y --no-install-recommends software-properties-common
RUN echo "deb http://repo.mongodb.org/apt/ubuntu $(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d= -f2)/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list

RUN apt-get update && apt-get install -y mongodb-org nodejs
RUN mkdir -p /data/db
ENTRYPOINT ["/usr/bin/mongod"]


ENV user nodegoat_docker
ENV workdir /usr/src/app/

# Home is required for npm install. System account with no ability to login to shell
RUN useradd --create-home --system --shell /bin/false $user

RUN mkdir --parents $workdir
WORKDIR $workdir
COPY package.json $workdir

# chown is required by npm install as a non-root user.
RUN chown $user:$user --recursive $workdir

# Then all further actions including running the containers should be done under non-root user.
USER $user
RUN npm install
COPY . $workdir

# Permissions need to be reapplied, due to how docker applies root to new files.
USER root
RUN chown $user:$user --recursive $workdir
RUN chmod --recursive o-wrx $workdir

RUN ls -liah
RUN ls ../ -liah
USER $user

# Neither of the following work, because the mongo container isn't yet running.
#RUN node artifacts/db-reset.js
#ONBUILD RUN node artifacts/db-reset.js
