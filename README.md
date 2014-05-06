# Supplejack Worker

The Supplejack Worker is a rails application that uses [Sidekiq](http://sidekiq.org/) to run all of the various jobs that occur in the harvesting and link checking process. To create and mange these jobs we recommend installing and configuring the [Supplejack Manager](https://github.com/DigitalNZ/supplejack_manager).

For more information on how to configure and use this application refer to the [documentation](http://digitalnz.github.io/supplejack)

## Getting started

Clone this repository and then rename `application.yml.example` to `application.yml`

Update the environment variables for each environment that you are using to reflect your setup. An example environment configuration is included below:

```yaml
staging:
  API_HOST: "http://api.harvester.org"            # The API to post to 
  MANAGER_HOST: "http://harvester.org"            # An instance of the Supplejack Manager
  MANAGER_API_KEY: "jRvU4MV5FGmhSoxpKrXz"         # API of a user on the Supplejack Manager
  HARVESTER_CACHING_ENABLED: true                 # Use caching 
  AIRBRAKE_API_KEY: "anc123"                      # Airbrake API key for error tracking
  LINKCHECKER_EMAIL: "linkchecker@harvester.org"  # Who to email if link checking fails
  LINK_CHECKING_ENABLED: "true"                   # Should link checking be enabled?
  HOST: 'worker.harvester.org'                    # The IP address or URL of this app
  SECRET_TOKEN: 'some long hash value'            # Hash for encryption
  DEVISE_MAILER: "info@harvester.org"             # Email address for Devise to use
  LINKCHECKER_RECIPIENTS: "bill@harvester.org"    # Who should be notified about link checking results 
  API_MONGOID_HOSTS: "localhost:27017"            # IP address of the Mongo instance for your API. Can be multiple values
```
Start your app using the following commands:

```bash 
# from the root of the application
bundle exec rails s -p 3002    # We recommend specifying a port to avoid conficts if you are using any other Supplejack apps

# in another terminal window run sidekiq to process jobs
bundle exec sidekiq
```

You should now be able to view the Sidekiq dashboard at http://localhost:3002/sidekiq

## Worker jobs
### Harvesting jobs
These use the harvester core gem to interpret a given parser which it uses to generate records and posts them to the Supplejack API (this is a simplified overview of the process).

### Link checking jobs 
There are two kinds of link checking. Collection checking checks a few records from a collection and suppresses collections which are unavailable. Record checking checks individual records which have been visited recently (in the API) and suppresses records which are unavailable.
