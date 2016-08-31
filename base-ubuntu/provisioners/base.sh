# https://github.com/mitchellh/packer/blob/master/website/source/docs/other/debugging.html.markdown#issues-installing-ubuntu-packages
echo 'waiting for cloud init to be finished...'
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done
echo 'adding repo'
add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe restricted multiverse"
echo 'updating and upgrading packages'
apt-get update
apt-get -y upgrade

echo 'installing python-pip, emacs, htop, ncdu, awscli'
apt-get install -y python-pip emacs24-nox htop ncdu
pip install awscli

# installing system packages needed for microservice and webapps
echo 'installing build-essential, ruby-dev, zlib1g-dev, liblzma-dev'
apt-get install -y build-essential ruby-dev zlib1g-dev liblzma-dev

echo 'installing chef client'
curl -L https://www.chef.io/chef/install.sh | sudo bash -s -- -v 12.8.1
echo 'setting up validator'
mkdir -p /etc/chef
mv /tmp/files/validator.pem /etc/chef/validation.pem
mv /tmp/files/encrypted_data_bag_secret /etc/chef/encrypted_data_bag_secret

echo 'creating ec2.hints for ohai'
mkdir -p /etc/chef/ohai/hints
touch /etc/chef/ohai/hints/ec2.json

echo 'moving the bootstrap script to init.d'
mv /tmp/files/chef-bootstrap /etc/init.d/
chmod +x /etc/init.d/chef-bootstrap
echo 'making chef bootstrap run on startup'
ln -s /etc/init.d/chef-bootstrap /etc/rc2.d/S99chef-bootstrap
echo 'adding chef deregister to init.d'
mv /tmp/files/chef-deregister /etc/init.d/
chmod +x /etc/init.d/chef-deregister
# not sure we want to deregister from chef just because we shut down
# this is something we should discuss
ln -s /etc/init.d/chef-deregister /etc/rc0.d/S10chef-deregister

# bootstraping chef solo to preinstall ruby
sudo mkdir -p /var/chef/cache /var/chef/cookbooks /etc/chef
echo 'downloading rbenv cookbook from cloudcruiser github repo'
wget -qO- https://github.com/CloudCruiser/ops_chef-cc_rbenv/archive/master.tar.gz | sudo tar xvzC /var/chef/cookbooks && sudo mv /var/chef/cookbooks/ops_chef-cc_rbenv-master /var/chef/cookbooks/cc_rbenv

#mv /tmp/files/cc-rbenv /var/chef/cookbooks/cc-rbenv
echo 'pulling down dep cookbooks'
for dep in apt build-essential rbenv chef_handler dmg git windows ohai yum yum-epel compat_resource mingw seven_zip sysdig htop homebrew
do
  wget -qO- https://supermarket.chef.io/cookbooks/${dep}/download | sudo tar xvzC /var/chef/cookbooks
done

# replace our tokens
sed -e "s|{{RUBY_VERSION}}|${RUBY_VERSION}|g" \
	/tmp/files/rbenv.json > /etc/chef/rbenv.json

echo 'bootstraping chef solo for rbenv'
chef-solo -j /etc/chef/rbenv.json && mv /etc/chef/rbenv.json /etc/chef/rbenv.done
echo 'bootstraping chef solo for sysdig'
chef-solo -o 'recipe[sysdig]' && touch /etc/chef/sysdig.done
