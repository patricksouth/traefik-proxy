# README

Deploys a Traefik Proxy in a DockerSwarm instance 
[https://doc.traefik.io/traefik/](https://doc.traefik.io/traefik/)

The **Traefik Proxy** is a quick and easy way to proxy services and manage **Letsencrypt** certificates for the proxied services.  

Proxied services can have their own public DNS hostnames, which can differ from the Traefik service FQDN (also a public DNS hostname).  

Some proxied services may NOT be able to consume the **Letsencrypt** acme.json file directly, that's where the **dumpcerts.acme.v2.sh** utility is handy for extracting public/private SSL certs from the acme.json file.  

Within the proxied service's directory, create a symlink to the _letsencrypt_ directory and call the **dumpcerts.acme.v2.sh** utility before deploying the proxied service.  

```
    ./letsencrypt/dumpcerts.acme.v2.sh ./letsencrypt/acme.json ./letsencrypt/ ${CLIENT_SERVICE_FQDN}  
```


An understanding of Traefik "labels" is essential when deploying proxied client services with Traefik.  
Read more about "labels" here: [https://doc.traefik.io/traefik/routing/providers/docker/](https://doc.traefik.io/traefik/routing/providers/docker/)

### USAGE

```
    ./deploy_traefik.sh [-logs | -stop | -H]  
```

## Configuration Before Deploying

Copy  **traefik.env.default** to **traefik.env** and update  
- ```TRAEFIK_HOST``` - add the public DNS hostname of the Traefik instance  
- ```TRAEFIK_VER``` - select available Traefik Docker image versions from - [https://hub.docker.com/_/traefik/tags](https://hub.docker.com/_/traefik/tags)  
- ```IPADDR``` - add the Docker Swarm's external IP Address  

Update **traefik.toml**  
- **email@address.com** add the email address you wish to provide to Letsencrypt for certificate notifications  
- **[api] dashboard** can be toggled to true, if access to the **/dashboard/** is required  
- **[log] level** value can be changed

Create **usersfile**  
If enabling the Traefik Dashboard, create and add values to the **usersfile**.  
Each user must be declared using the **name:hashed-password** format using `htpasswd`.  

## Note

* When used in **docker-compose.yml**, all dollar characters **$** need to be doubled **$$** for escaping.
* to create user:password pair, it's possible to use the following command:  

```
        echo $(htpasswd -nB user) | sed -e s/\\$/\\$\\$/g
```


* note that dollar characters should NOT be doubled when they not evaluated (e.g. Ansible docker_container module).  

Add any Traefik middleware items to the **dynamic/middlewares.toml** file.


## Acknowledgement ##
dumpcerts.acme.v2.sh is not my work, but is sourced and modified from 
[https://github.com/hardware/mailserver](https://github.com/hardware/mailserver)
under the MIT License (MIT).

Copyright (c) 2017 Brian 'redbeard' Harrington <redbeard@dead-city.org>
https://github.com/hardware/mailserver/blob/master/rootfs/usr/local/bin/dumpcerts.acme.v2.sh
