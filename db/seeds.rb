common_classes = %w(
git
ntpd
vim
zip
osadmin
)
vanilla_classes = %w(
oss_apache
elinks
java170
jce_policy
jruby
oss_jboss
sslcertificates
oss_apache::ssl_vhost
oss_apache::vhost
mariadb_user
mariadb_server
deploy_office_space
deploy_backup_cron
)

common_classes.each { |klass| NodeClass.create name: klass }
vanilla_classes.each { |klass| NodeClass.create name: klass }

%w(common oss_vanilla).each do |group|
  NodeGroup.create name: group
end

# create a common group:
common_group = NodeGroup.find_by_name "common"
common_classes.each do |common|
  common_group.node_classes << NodeClass.find_by_name(common)
end
common_group.save

# create a vanilla group that inherits common group
vanilla_group = NodeGroup.find_by_name "oss_vanilla"
vanilla_classes.each do |vanilla|
  vanilla_group.node_classes << NodeClass.find_by_name(vanilla)
end
vanilla_group.node_groups << common_group
vanilla_group.save

#### PARAMETERS ####
params_str = IO.readlines("#{Rails.root}/config/seed_params.yml").join()
parameters = YAML.parse(params_str).to_ruby
vanilla_group.node_classes.each do |nc|
  next if parameters[nc.name] == nil
  ngcm = nc.node_group_class_memberships.create node_class: nc
  parameters[nc.name].each do |key,val|
    Parameter.create parameterable_id: nc.id, parameterable_type: "NodeGroupClassMembership", key:key, value: val
  end
end

client1 = Node.create  name: "client1"
client1.node_groups << vanilla_group
client1.save!
