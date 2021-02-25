# copied from k8s offical site
    #(https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
    $ source <(kubectl completion bash) 
    $ echo "source <(kubectl completion bash)" >> ~/.bashrc 
    $ alias k=kubectl
    $ complete -F __start_kubectl k
    $ alias setns="kubectl config set-context --current --namespace" 
    $ alias runtmp="kubectl run -it --rm busybox --image=busybox -- sh"
    # In runtmp alias I added --rm so pod should delete after test
    $ export do="--dry-run=client -o yaml" # copied from k8s offical site
    $ export kill="--grece-period=0 --force" # typed myself
    $ export binsh="-- /bin/sh -c"  # typed myself
    Vi settings to indent yaml file(# typed myself)
    $ vi ~/.vimrc
    $ set ts=2 sw=2 expandtab
    $ set nu
