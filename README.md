# vmware_kali_setup

rm -rf ~/Downloads/* && rm -rf ~/Desktop/vmware_kali_setup-main && rm -rf ~/bootstrap-kali

bash ~/Desktop/vmware_kali_setup-main/main_vmware.sh

sudo ansible-playbook -i /home/my/bootstrap-kali/inventory.ini /home/my/bootstrap-kali/site.yml