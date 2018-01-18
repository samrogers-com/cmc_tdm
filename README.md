# cmc-tdm

CMC tamper detection mechanism

 This script will test to see if new file has be added or remove to the CMC since a baseline was taken.


 You can define the hostname here if you want or let it find it in the /etc/hosts file.
 This will require that the cmc for the UV is the only CMC define in the /etc/hosts
 
This presumes that the CMC has the ssh-key from *-SMS system so this can run automatically
 without entering a password for the CMC.
