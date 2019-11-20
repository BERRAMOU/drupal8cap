This is an example of capistrano configuration for Drupal 8.

1. Clone this repo into your drupal root directory

``` 
cd /YOUR_DRUPAL_DIR/ 
git clone git@github.com:BERRAMOU/drupal8cap.git
``` 

2. Install dependencies 

```
cd drupal8cap
bundle install
```

3. Change your server information.
Change the following from **drupal8cap/config/deploy.rb** 
* APP_NAME : Set you app name
* REPO_URL : Set your repo url e.g *git@bitbucket.org:user_name/repo.git* or *git@github.com:user_name/repo.git*
* /usr/local/bin/composer.phar :  change this with your actual composer.phar path in the server

4. Setup your env configuration:
There is an example of EVN **_staging.rb_** you can change the configuration or copy/paste it as another env like for example production.rb and don't forget to fill it out with your configuration.
 Change:
 * GIT_BRANCH : Branch name e.g develop, master ...
 * TMP_DIR_PATH :  Tmp directory e.g PATH_TO_HOME/tmp  
 * DEPLOY_TO_DIR : Deploy directory e.g /home/site_name/www 
 * CURRENT_DIR : Current directory of your site exp public_html 
 * INSTANCE_TYPE : Instance type e.g staging / development / production
 * SERVER_IP_ADDRESS : Server ip address.
 * USER : Server user 
 
5. Deployment : to deploy an instance <INSTANCE> .
```
cap <INSTANCE> deploy
```
Exp:

```
cap staging deploy
```

  
