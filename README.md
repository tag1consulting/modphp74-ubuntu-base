# PHP Base Dockerfile
A Dockerfile for Apache & PHP to be used as a base image for building Drupal app container images.

Images that use this as a base are responsible for:
* Configuring VirtualHost(s)
* Exposing port(s)

## Usage
Apache must be configured in the app image definition (along with the app itself).

### Example Apache VirtualHost Config
This is a generic Apache Virtualhost example that could be included in an app container built from this image:

```apache
ServerTokens Prod
ServerName localhost
Listen 8080
	
<VirtualHost *:8080>
	DocumentRoot /var/www/html

	<Directory /var/www/html >
		AllowOverride All
		Require all granted
	</Directory>
	SetEnvIf X-Forwarded-Proto https HTTPS=on
</VirtualHost>
```

In app's Dockerfile:
```Dockerfile
COPY apache.conf /etc/apache2/sites-available/000-default.conf
EXPOSE 8080
```
