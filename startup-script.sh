#!/bin/bash

apt-get update
apt-get install -y apache2 libapache2-mod-php

systemctl enable apache2
systemctl restart apache2