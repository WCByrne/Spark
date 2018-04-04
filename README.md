![Spark](https://raw.githubusercontent.com/WCByrne/Spark/master/img/header.png "Spark")

Spark is a general purpose http request runner

##  Features
* Save responses to files
* OAuth authentication
* Reusable auth tokens
* Config file for consistent runs


## Possible Uses
* Save responses for tests
* Diff responses to check for changes
* Use respones for documentation examples
* Whatever you dream up

## Communication
* Questions: **[@wcbyrne](https://twitter.com/wcbyrne/)**
* Bug/request: **[Issues](https://github.com/WCByrne/Spark/issues)**


## Installation

...

## Getting Started

Spark uses a config file to define the requests to make. Getting your config started is as easy as:

```
spark init [-o path]
```
This will create a template config as `spark.json`. By default it will be created in the current directory but you can set a path using `-o`.

Open up spark.json in a text editor, preferrably one that has json support. 

## The Config File

The config file defines the requests that should be made when running spark. The top level keys are global to all requests, or "cases". Each case then provides options per request.
> 
> <a name="service"></a>
> **service** `String`
> 
> The base url for your requests (ex https://api.myservice.com)
> 
> **output** `Path`
> 
> A directory to save respones to. This can also be set when running spark later.
> 
> **oauth** `Dictionary` 
> 
> Optionally define your oauth tokens for authenticated requests. See **[oauth](#oauth)** for more
> 
> **headers** `Dictionary`
> 
> HTTP header key-value pairs. As usual with headers, all values must be strings.
> 
> **cases** `Array`
> 
> A list of requests to be made. See **[Cases](#cases)**


<a name="cases"></a>
## Cases

Each case uses the properties defined by the top level properties defined in your config file. Some properties may be futher customized per case.


> **name** `String`
> 
> The name of the file to save the response to.
> 
> **method** `String`
> 
> The HTTP method for the request
> 
> **path** `String`
> 
> The url path to be called on the defined **[service](#service)**
> 
> **headers** `Dictionary`
> 
> Custom headers for the request. Will override global headers if any are defined.
> 
> **params** `Dictionary`
> 
> Query parameters. All keys and values must be strings.
> 
> **body** `Dictionary or Array`
> 
> Any valid JSON body to send with the request.
> 
> <a name="case-token"></a>
> **token** `String`
> 
> The name of a oauth token defined in oauth.tokens. See **[OAuth](#oauth)** for more.


<a name="oauth"></a>
## OAuth

The oauth option defines the credentials for each case cases in the config file.  

> **consumer** `Dictionary`
> 
> The consumer key and secret used for all requests
> 
> **token** `Dictionary`
> 
> The default client key and secret used for all requests (optional.
> 
> **tokens** `Dictionary`
> 
> While the key and secret in `token` are the default for all requests. It may be necessary to perform requests with different client tokens.
> 
> Rather than duplicate these per request tokens in each case they are defined globally and referrened by name in each case (see **[case token](#case-token)**).
> 
> <details>
> <summary>Example</summary>
> 
> ```json
> {
> 	"consumer": { },
> 	"token": { },
> 	"tokens": {
> 		"user-1" : {
> 			"key" : "<key-for-user-1>",
> 			"secret": "<secret-for-user-1>"
> 		},
> 		"user-2": {
> 			"key": "<key-for-user-2>",
> 			"secret": "<secret-for-user-2>"
> 		}
> 	}
> }
> ```
> </details>


#### SECURITY NOTE 
If your config file contains oauth tokens be careful of publishing them with your project repo. You may consider checking in a config-base.json file with tokens removed and adding spark.json to your .gitignore. 

## Config Example

```
{
    "service": "http://api.service.com",
    "headers": {},
    "output": "./SparkResponses",
    "oauth": {
        "consumer": {
            "key": "<key>",
            "secret": "<secret>"
        },
        "token": {
            "key": "<key>",
            "secret": "<secret>"
        }
    },
    "cases": [
        {
            "name": "FetchDrafts",
            "method": "GET",
            "path": "/v1/posts",
            "headers": null,
            "params": {
            		"status": "draft"
            },
            "body": null
        },
        {
            "name": "CreatePost",
            "method": "POST",
            "path": "/v1/posts",
            "headers": {},
            "body": {
            		"title": "About Spark",
            		"body": "Well, it's kind of awesome."
            }
        }
    ]
}
```

## Credits

OAuth signing thanks to **[OhhAuth](https://github.com/mw99/OhhAuth)**
