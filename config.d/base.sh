#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
set -x

# Do some changes ...

user=${user:-vagrant}

## install packages

su - ${user} -c "bash -ex" <<'EOS'
  addpkgs="
   npm
  "

  if [[ -z "$(echo ${addpkgs})" ]]; then
    exit 0
  fi

  deploy_to=/var/tmp/buildbook-rhel6

  if ! [[ -d "${deploy_to}" ]]; then
    git clone https://github.com/wakameci/buildbook-rhel6.git ${deploy_to}
  fi

  cd ${deploy_to}
  git checkout master
  git pull

  sudo ./run-book.sh ${addpkgs}
EOS

su - ${user} -c "bash -ex" <<'EOS'
  if ! [[ -d stackedit ]]; then
    git clone https://github.com/benweet/stackedit.git
  fi
  cd stackedit
  git checkout v3.1.9

  npm install
 #nohup node server.js &
EOS

cat <<-'EOS' > /etc/init/stackedit.conf
	description stackedit

	respawn
	respawn limit 5 60

	script
	  sleep 3
	  su - vagrant -c "node /home/vagrant/stackedit/server.js"
	end script
	EOS

initctl stop  stackedit || :
initctl start stackedit

su - ${user} -c "bash -ex" <<'EOS'
  curl -fSkL https://raw.githubusercontent.com/hansode/env-bootstrap/master/build-personal-env.sh | bash
EOS
