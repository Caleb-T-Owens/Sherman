# Ansible

## `inventory.ini`

Lists out all of the servers managed by Ansible.

They need to be accessible via SSH from the control node.

I'm using tailscale ssh to connect to the servers.

Ansible will by default try to use your local user's name to connect to the servers. We can override this by setting the `ansible_user` variable in the inventory file.

## `playbook.yml`

Defines the tasks to be executed.

```
$ ansible-playbook -i inventory.ini playbook.yml
```
