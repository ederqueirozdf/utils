<h1 align="center">LVM 👋</h1>

## Author
👤 **Eder Queiroz**
* Github: [@ederqueirozdf](https://github.com/ederqueirozdf)

## 🤝 Contribuições são bem vindas
Linux ❤️
<hr>
## Criar Volumes

#### 1. Procedimento

- Após adicionado novo disco no servidor virtual, seguir os passos:

##### 1.1 Scan Disco

Ao efetuar a entrega dos discos para a máquina virtual, é necessário que o linux reconheça os discos entregues

    echo "- - -" > /sys/class/scsi_host/host0/scan

* *É importante executar o scan em todos os hosts_scsi, caso haja mais de um. Ex. host0 / host1 / host2...*

##### 1.2 Listar Disco

Após executar o scan em todos os discos, verifique com o comando **"fdisk -l"** se o disco está disponível

    # fdisk -l

Identificado o disco, execute a formatação:

    # mkfs.xfs /dev/sdb

##### 1.3 Criar Volume Físico

No exemplo utilizaremos a unidade **/dev/sdb**, sendo assim deve-se criar o volume físico com o comando:

    # pvcreate /dev/sdb

Criado o volume, é possível listar com o comando:

    # pvdisplay


##### 1.4 Criar Volume Grupo Existente

Com o comando **vgdisplay** é possível listar os grupos de volumes já criados. Porém, vamos criar um novo volume group para a entrega do disco entregue à máquina virtual. Execute os comandos:

    # vgcreate "nomedogrupo" /dev/sdb (disco entregue)
    ex.:
    # vgcreate "vg_data" /dev/sdb


Para listar os volumes criadas execute o comando:

    # vgdisplay


##### 1.5 Novo Volume Lógico

Disponibilizado o disco para o Volume Grupo, agora vamos criar o volume lógico do disco e entregar ao volume grupo criado conforme passo anterior, Execute:

    # lvcreate -l +100%FREE -n "nome do volume logico" "nome do volume grupo criado"
    Ex.:
    # lvcreate -l +100%FREE -n dados vg_data

Para listar os volumes lógicos execute o comando:

    #lvdisplay

Por fim, vamos formartar o volume lógico criado e configurar a partição para montagem no arquivo **"/etc/fstab"**.

Para formatar a partição lógica, execute o comando:

    # mkfs.xfs /dev/mapper/vg_data-dados

Para descobrir o UUID do disco configurado, execute o comando **blkid**, em seguida vamos configurar o arquivo **"/etc/fstab"**

    # blkid /dev/mapper/vg_data-dados

No arquivo fstab, adicionaremos a seguinte linha:

    # UUID=c6f410e4-fb47-43c6-ba67-21e756adac39       /dados   xfs  defaults 0 0

Para finalizar, execute o comando **"mount -a"** para que as partições listadas no arquivo de configuração do fstab sejam montadas:

    # mount -a

Verifique se a partição foi montada com o comando "df -hT"

    # df -hT
    /dev/mapper/vg_data-dados xfs       2.0T   33M  2.0T   1% /dados


## Extender Volumes

#### 1. Procedimento

##### 1.1 Scan Disco

Ao efetuar a entrega dos discos para a máquina virtual, é necessário que o linux reconheça os discos entregues, para isso, execute os comandos abaixo para efetuar o scanner nos hosts mapeados: 

    echo "- - -" > /sys/class/scsi_host/host0/scan

* *É importante executar o scan em todos os hosts, caso haja mais de um. Ex. host0 / host1 / host2...*

##### 1.2 Listar Disco
Após executar o scan em todos os discos, verifique com o comando **"fdisk -l"** se o disco está disponível

    fdisk -l
    
    Disk /dev/sdb: 53.7 GB, 53687091200 bytes, 104857600 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes

##### 1.3 Criar Volume Físico

Identifique o disco que foi entregue conforme o comando executado no ítem 1.2.
No exemplo nosso disco foi listado como a unidade **/dev/sdb**, sendo assim deve-se criar o volume físico com o comando:

    pvcreate /dev/sdb

##### 1.4 Extender Volume Grupo Existente

Para extender o grupo de volume já existente deve-se entregar o volume criado no passo anterior ao grupo de volumes que foi configurado no LVM da máquina virtual.

Com o comando **vgdisplay** é possível listar os grupos de volumes já criados. Execute o comando conforme exemplo abaixo:

    vgdisplay
    [root@~ eder]# vgdisplay
      --- Volume group ---
      VG Name               centos_srv210vm01
      System ID
      Format                lvm2

No exemplo, verificamos que o nome do volume (VG Name) foi criado com o nome: **"centos_srv210vm01"**, sendo assim, o volume devará será extendido com o seguinte comando:

	vgextend centos_srv210vm01 /dev/sdb

* Extensão do volume grupo *centos_srv210vm01* utilizando o disco entregue */dev/sdb*.
* Verificar se a expansão do volume foi efetuada com comando **vgdisplay**. 

##### 1.5 Extender Volume Existente

Disponibilizado o disco para o Volume Grupo existente, conforme ítem 1.4, agora, deve-se extender o volume com o disco entregue ao grupo, para isso execute o comando:

     lvextend -l +100%FREE /dev/mapper/centos_srv210vm01-var
    
* No exemplo o tamanho total disponível no volume está sendo entregue ao volume grupo.

**Por fim, deve-se efetuar o "resize" do volume a ser expandido, no exemplo utilizado *"/var"*:**

Para volumes xfs:

    xfs_growfs /var

Para volumes ext4:

    resize2fs /var


