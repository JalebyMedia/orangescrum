#!/bin/bash
#Orangescrum installation in Centos 7 Server:-
#============================================
WEBROOT=/var/www/html
APPROOT=/var/www/html/orangescrum-master
DATABASE=orangescrum
DUSER=orangescrum
DPASS=Orang3#Scrum
mysqlversion=5.6
mysqlversion1=5.5
mysqlversion2=5.7
apacheversion=2.4
phpversion=5.6
phpversion70=7.0
phpversion71=7.1
phpversion72=7.2
mysqlv8=8.0
mysql_v=`rpm -qa | grep "mysql.*server" | cut -c 24-26`
mysql_v8=`rpm -qa | grep "mysql.*server" | cut -c 24-26`
Apache_ver=`rpm -qa | grep httpd-2 | cut -c 7-9`
php_ver=`php -v | grep -i php | awk 'NR == 1' | cut -c 5-7`
#php_ver=`rpm -qa | grep "php.*common" | cut -c 15-17`
#mysql_ver=`mysql -V | awk '{ print $5 }' | cut -c 1-3`
#Apache_v=`httpd -v | grep -i Apache |awk '{ print $3 }'| cut -c 8-10`
#php_v=`php -v | grep -i "PHP 5.6.35"|awk '{ print $2 }'| cut -c 1-3`
clear
echo "You need a fresh OS for OrangeScrum Community to work with"
echo "Orangescrum will work with MySQL 5.5-5.7, Apache Web Server 2.4 amd PHP 5.6, 7.0 & 7.2"

#MySQL-Server
if [ "$mysql_v" = "$mysqlversion" ] || [ "$mysql_v" = "$mysqlversion1" ] || [ "$mysql_v" = "$mysqlversion2" ]; then
        echo "Found MySQL $mysql_v, on this Server"
	elif [ "$mysql_v" = "$mysqlv8" ]; then 
         clear
         echo "Found MySQL Database Version $mysql_v8 on this Server"
         echo "Orangescrum Community Edition will only work with MySQL 5.5, 5.6 and 5.7"
         echo "If you are running any other application with MySQL 8.0 on this Server"
         echo "then consider using another server for Orangescrum Community Edition."
         echo "OR"
         echo "Uninstall MySQL Database Server $mysql_v8 and run Orangescrum setup again..."
                exit 1
else
	echo "MySQL Server not found on this Server"
fi

#Apache Web Server
if [ ! -z "$Apache_ver" ]; then
	echo "Found Apache Web Server $Apache_ver on your Server"
	echo "If you are running any other application with the current versions of Apache, unistalling Apache Web Server $Apache_ver might create issue"
else
	echo "Apache Web Server not found on this Server"
fi

#PHP Packages on your Server
if [ ! -z "$php_ver" ]; then
	echo "Found PHP $php_ver on your Server"
	echo "If you are running any other application with the current versions of PHP, unistalling PHP-$php_ver might create issue"
else
	echo "PHP and required extensions not found on this Server"
fi

echo "Do you want to Continue Installation, type Y/N"
read action

if [[ $action == "y" || $action == "Y" || $action == "yes" || $action == "Yes" ]]; then
        echo "Continue to Application Installation and Configuration"
else
        echo "Aborting Installation"
        exit 1
fi

echo "OrangeScrum Installation Started, Please Wait"
#Add Firewall rules for Apache and mysql
#Updating package manager
wgetiver=`rpm -qa | grep wget | cut -c 1-4`
wgetversion=wget
if [ "$wgetiver" = "$wgetversion" ]; then
        echo "wget is already installed, Continue Installation"
else
        yum install -y wget
fi

#Add Firewall rules for Apache and mysql
echo `setenforce 0`
echo `getenforce`
sed -i "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config

frwald=`rpm -qa | grep firewalld | tr -s ' ' | cut -c 1-9`
firwald=firewalld
if [ "$frwald" = "$firwald" ]; then
	firewall-cmd --permanent --zone=public --add-service=http
	firewall-cmd --permanent --zone=public --add-service=mysql
	firewall-cmd --permanent --zone=public --add-service=https
	firewall-cmd --reload
else
	echo "Firewalld is not installed, not setting up firewall rules"
fi

#MySQL-Server Uninstall
if [ "$mysql_v" = "$mysqlversion" ] || [ "$mysql_v" = "$mysqlversion1" ] || [ "$mysql_v" = "$mysqlversion2" ]; then
        echo "Found MySQL $mysql_v, Continue Installation"
	echo "Please enter the currently installed MySQL database root password"
	read -s DBPASS
else
        echo "Installing MySQL Server"
	yum -y install epel-release yum-utils
	yum -y localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
	yum -y install mysql-community-server
	systemctl enable mysqld
	service mysqld restart
	clear
	echo "Password should be combination of Alpha numeric with special characters"
	echo "Enter New Root Password for MySQL Database:"
	read -s DBPASS
	DBTPASS=`cat /var/log/mysqld.log | grep 'temporary password' | awk '{print $NF}'`
	yum install -y expect
	echo "--> Set root password"
	echo "--> Set Security Paramaeters for MySQL"
        SECURE_MYSQL=$(expect -c "
        set timeout 10
        spawn mysql_secure_installation
        expect \"Enter current password for root (enter for none):\"
        send \"${DBTPASS}\r\"
	expect \"Please set a new password\"
        send -- \"${DBPASS}\r\"
        expect \"Re-enter new password:\"
        send -- \"${DBPASS}\r\"
        expect \"Change the password for root ?\"
        send -- \"n\r\"
        expect \"Remove anonymous users?\"
        send \"y\r\"
        expect \"Disallow root login remotely?\"
        send \"y\r\"
        expect \"Remove test database and access to it?\"
        send \"y\r\"
        expect \"Reload privilege tables now?\"
        send \"y\r\"
        expect eof
        ")
        echo "$SECURE_MYSQL"
        yum remove -y expect
fi



#Apache Web Server Uninstall older version and install required version
if [ "$Apache_ver" = "$apacheversion" ]; then
        echo "Found Apache $Apache_ver, Continue Installation"
	elif [ $Apache_ver ! = $apacheversion ]; then
        	echo "Uninstalling Apache Web Server $Apache_ver from your Server"
        	yum remove -y `rpm -qa | grep httpd |awk '{print $2}'`
else
        echo "Installing Apache Web Server"
        yum install -y httpd
        systemctl enable httpd
	service httpd restart
fi

#PHP Packages Uninstall
if [ "$php_ver" = "$phpversion70"  ] || [ "$php_ver" = "$phpversion71" ] || [ "$php_ver" = "$phpversion72" ]; then
        echo "Found PHP $php_ver, Installation will continue..."
	elif [ "$php_ver" = "$phpversion" ]; then
	        echo "Uninstalling PHP $php_ver from your Server"
		yum -y  remove `rpm -qa | grep php`
	else
            echo "Installing PHP 7.2 and all the required extensions"
            yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
            yum-config-manager --enable remi-php72
	    yum install -y php php-cli.x86_64 php-common.x86_64 php-bcmath.x86_64 php-dba.x86_64 php-embedded.x86_64 php-enchant.x86_64 php-fpm.x86_64 php-gd.x86_64 php-imap.x86_64 php-intl.x86_64 php-ldap.x86_64 php-mbstring.x86_64 php-mcrypt.x86_64 php-mysql.x86_64 php-pdo.x86_64 php-pecl-zip.x86_64 php-pecl-memcache.x86_64 php-pecl-imagick.x86_64 php-soap.x86_64 php-tidy.x86_64 php-xml.x86_64 php-opcache.x86_64
	    service httpd restart
fi

php_version=`php -v | grep -i php | awk 'NR == 1' | cut -c 5-7`
if [ "$php_version" = "$phpversion70"  ] || [ "$php_version" = "$phpversion71" ] || [ "$php_version" = "$phpversion72" ]; then
        echo "Found PHP $php_version, Installation will continue..."
else
	echo "PHP not installed correctly, exiting setup"
	exit 1
fi

#Set application Directory
find / -name '*orangescrum-centos7*' -exec mv -t $WEBROOT/ {} + > /dev/null 2>&1
mv $WEBROOT/orangescrum-centos7-php7 $WEBROOT/orangescrum-master

phpadminv=`rpm -qa | grep -i phpmyadmin| awk '{print $2}' |tr "\n" " "`
phpadminver=phpMyAdmin
#Install phpMyAdmin(To access database Using UI)
if [ "$php_version" = "$phpversion70"  ] || [ "$php_version" = "$phpversion71" ] || [ "$php_version" = "$phpversion72" ]; then
	echo "Installing phpMyAdmin"
	yum install -y phpmyadmin
else
	echo "PHP $phpversion not installed, phpMyAdmin will not be installed"
fi

#Installing additional required packages
vim_fs=`rpm -qa | grep vim-filesystem | cut -c 1-14`
vim_comm=`rpm -qa | grep vim-common | cut -c 1-10`
vimenh=`rpm -qa | grep vim-enhanced | cut -c 1-12`
htmltpdf=`rpm -qa | grep wkhtmltopdf | cut -c 1-11`
vimenhance=vim-enhanced
vimfs=vim-filesystem
vimcomm=vim-common
htmlpdf=wkhtmltopdf

if [ "$vim_fs" = "$vimsfs" ] && [ "$vim_comm" = "$vimcomm" ] && [ "$vimenh" = "$vimenhance" ]; then
        echo "VIM editor already installed"
else
        yum -y install vim
fi

if [ "$htmltpdf" = "$htmlpdf" ]; then
        echo "html to pdf already installed"
else
        yum -y install wkhtmltopdf
fi


#To access phpmyadmin in browser and app to work properly, the following things to be changed 
#    	* Change the 'post_max_size' and `upload_max_filesize` to 200Mb in php.ini
# and some additional parameters
echo "Changing PHP parameters" 
sed -i "s/post_max_size = /; post_max_size = /g" "/etc/php.ini"
sed -i "/; post_max_size = /apost_max_size = 200M" "/etc/php.ini"
sed -i "s/upload_max_filesize = /; upload_max_filesize = /g" "/etc/php.ini"
sed -i "/; upload_max_filesize = /aupload_max_filesize = 200M" "/etc/php.ini"
sed -i "s/max_execution_time = /; max_execution_time = /g" "/etc/php.ini"
sed -i "/; max_execution_time = /amax_execution_time = 300" "/etc/php.ini"
sed -i "s/memory_limit = /; memory_limit = /g" "/etc/php.ini"
sed -i "/; memory_limit = /amemory_limit = 512M" "/etc/php.ini"
sed -i "/; max_input_vars = /amax_input_vars = 5000" "/etc/php.ini"

# Allow Apache to override all to make the apllication to work.
echo '# Change AllowOverride to All for the application to work
<Directory /var/www/html/>
   Options Indexes FollowSymLinks
   AllowOverride All
   Require all granted
</Directory>' >> /etc/httpd/conf/httpd.conf

mv /etc/httpd/conf.d/phpMyAdmin.conf /etc/httpd/conf.d/phpMyAdmin.conf_old
cp -f $APPROOT/phpMyAdmin.conf /etc/httpd/conf.d/
chmod 644 /etc/httpd/conf.d/phpMyAdmin.conf

# General Configuration management: MySQL:
# If STRICT mode is On, turn it Off.
#Disable Strict mode on mysql for Centos/Fedora  :-
#Change sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES in my.cnf
#to sql_mode=""
echo "Setting up MySQL Restriction mode"
sed -i '/symbolic-links=0/a# \n# Recommended in standard MySQL setup\nsql_mode=""' /etc/my.cnf
sed -i 's/sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES/sql_mode=""/g' /etc/my.cnf

service mysqld restart

#Provide proper write permission to " app/tmp ", " app/webroot " and " app/Config " folders and their sub folders.
cd $WEBROOT
chown -R apache:apache orangescrum-master
chmod -R 0755 orangescrum-master
cd $APPROOT
chmod -R 0777 app/tmp

#Create Database and User for OS and authorize the user to the database.
mysql -uroot -p$DBPASS -e "CREATE DATABASE $DATABASE";
mysql -uroot -p$DBPASS -e "CREATE USER $DUSER@'localhost' IDENTIFIED BY '$DPASS'";
mysql -uroot -p$DBPASS -e "GRANT ALL PRIVILEGES ON $DATABASE.* TO '$DUSER'@'localhost'";

#Import database sql file:
#Navigate to application directory and import the database
cd $APPROOT
mysql -u orangescrum -p$DPASS orangescrum < database.sql

#Installing cron jobs
echo "Installing cronjobs"
echo "00 23 * * * php -q /var/www/html/orangescrum-master/app/webroot/cron_dispatcher.php /cron/email_notification" | tee -a /var/spool/cron/root >> /dev/null
echo "*/15 * * * * php -q /var/www/html/orangescrum-master/app/webroot/cron_dispatcher.php /cron/dailyupdate_notifications" | tee -a /var/spool/cron/root >> /dev/null
echo "*/15 * * * * php -q /var/www/html/orangescrum-master/app/webroot/cron_dispatcher.php /cron/dailyUpdateMail" | tee -a /var/spool/cron/root >> /dev/null
echo "*/30 * * * * php -q /var/www/html/orangescrum-master/app/webroot/cron_dispatcher.php /cron/weeklyusagedetails" | tee -a /var/spool/cron/root >> /dev/nul

echo "Please enter your email id"
read USER_NAME
echo "Please enter your email password"
read -s EPASSWD
echo "Please enter your Domain Name or IP"
read DNAME_IP
echo "Please enter your SMTP Host"
read SMTP_ADDR
echo "Please enter your SMTP port"
read SMTP_PORT

#virtualhost
cp -f $APPROOT/orangescrum.conf /etc/httpd/conf.d/
chmod 644 /etc/httpd/conf.d/orangescrum.conf
sed -i "s/ServerAdmin Email_id_of_Admin/ServerAdmin "$USER_NAME"/" "/etc/httpd/conf.d/orangescrum.conf" >> /dev/null
sed -i "s/ServerName IP_Domain name/ServerName "$DNAME_IP"/" "/etc/httpd/conf.d/orangescrum.conf" >> /dev/null
service httpd restart

#Change Email Parameters
sed -i "s/SMTP_UNAME =/#SMTP_UNAME = /" "$APPROOT/app/Config/config.ini.php"
sed -i "/#SMTP_UNAME =/aSMTP_UNAME = "$USER_NAME"" "$APPROOT/app/Config/config.ini.php"
sed -i "/#SMTP_UNAME =/d" "$APPROOT/app/Config/config.ini.php"
sed -i "s/SMTP_PWORD =/#SMTP_PWORD = /" "$APPROOT/app/Config/config.ini.php"
sed -i "/#SMTP_PWORD =/aSMTP_PWORD = "$EPASSWD"" "$APPROOT/app/Config/config.ini.php"
sed -i "/#SMTP_PWORD =/d" "$APPROOT/app/Config/config.ini.php"
sed -i "s/SMTP_HOST =/#SMTP_HOST = /" "$APPROOT/app/Config/config.ini.php"
sed -i "/#SMTP_HOST =/aSMTP_HOST = ssl:\/\/"$SMTP_ADDR"" "$APPROOT/app/Config/config.ini.php"
sed -i "/#SMTP_HOST =/d" "$APPROOT/app/Config/config.ini.php"
sed -i "s/SMTP_PORT =/#SMTP_PORT = /" "$APPROOT/app/Config/config.ini.php"
sed -i "/#SMTP_PORT =/aSMTP_PORT = "$SMTP_PORT"" "$APPROOT/app/Config/config.ini.php"
sed -i "/#SMTP_PORT =/d" "$APPROOT/app/Config/config.ini.php"

clear
echo "OrangeScrum Community Edition Installation Completed Successfully."
echo "Open you browser and access the application using the domian/IP address:"
echo "http://Your_Domain_or_IP_Address/"
