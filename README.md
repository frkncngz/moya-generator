# moya-generator

A tool that generates several Moya providers and models from given config files.

## Installation
1. Add `pod 'moya-generator', :podspec => 'https://raw.githubusercontent.com/frkncngz/moya-generator/master/moya-generator.podspec'` to your Podfile and `pod install`
2. In Xcode: Click on your project in the file list, choose your target under TARGETS, click the Build Phases tab and add a New Run Script Phase by clicking the little plus icon in the top left
3. Paste the following script:
```
"${PODS_ROOT}"/moya-generator/moya-generator/moya-generator --inputPath "$SRCROOT"/provider-configs/ --outputPath "$SRCROOT"/"$PROJECT_NAME"
```

## Usage
1. Create a `provider-configs` folder in your project's root directory
2. Place your json configurations in that folder
3. Build your project and you will see a newly created `Providers` folder with the generated providers and models.

## Configuration
- `providerName`: Name of the provider
- `custom`: (Optional) If you set this to `true`, the Provider and Models will be created only once (if they are not present). If they are created before, the generator will not overwrite them so you can modify them and create custom providers.
- `baseURL`: Base URL of the API
- `headers`: Default headers
- `endpoints`: An array that defines the endpoints
  - `name`: Name of the endpoint (enum)
  - `altName`: (Optional) Alternative name which can be used in parameterMapping.
  - `path`: Path of the endpoint from baseURL
  - `method`: Method of the endpoint (post, get, put etc)
  - `task`: This can be `data`, `plain` and `parameters`. `plain` and `data` are harcoded and generates `return .requestPlain` and `return Task.requestData(data)` respectively. If you set this to `parameters`, it will generate a request with these parameters
  - `parameters`: An array that defines the parameters
    - `name`: Name of the parameter
    - `type`: Type of the parameter (String, Bool etc)
    - `outputName`: (Optional) If you want to change the name of the parameter while building the request, you should set it here
    - `fixedValue`: (Optional) If you want to set a fixed value to the parameter, you can set it here. If you set this, the parameter will be discarded from other places
  - `parameterMapping`: (Optional) If you want to interfere with the parameters before sending the request, this is the place to do it. This dictionary will be your final parameters. Currently it only supports `$parameters` and `$altName` keys. `$parameters` will get all the parameters from the request.

  If you set this:
  ```json
  {
	"params": "[$parameters]",
	"method": "$altName"
  }
  ```
  
  Your final request parameters will look like this:
  ```swift
  {
	  "method": "alt name that is set in the json",
	  "params": [
  		  [
			  "param1": "value1",
  		  	  "param2": "value2",
	  		  "param3": "value3"
		  ]
	  ]
  }
  ```
- `models`: An array that defines the Codable models
  - `name`: Name of the model
  - `equatable`: (Optional) If you set this to true, it will add Equatable protocol next to Codable.
  - `parameters`: An array that defines the variables
    - `name`: Name of the variable
    - `type`: Type of the variable
    - `outputName`: (Optional) If you set this, the generator will add CodingKeys enum corresponding to this variable.

    ### Example
    ```json
    {
      "providerName":"ExampleRPC",
      "custom":true,
      "baseURL":"https://example-rpc.trustwalletapp.com",
      "headers":{
        "content-type":"application/json",
        "accept":"application/json"
      },
      "endpoints":[
        {
          "name":"account",
          "altName":"account_info",
          "path":"/",
          "method":"post",
          "task":"parameters",
          "parameters":[
            {
              "name":"address",
              "outputName":"account",
              "type":"String"
            },
            {
              "name":"strict",
              "type":"Bool",
              "fixedValue":"true"
            },
            {
              "name":"ledger_index",
              "type":"String",
              "fixedValue":"\"current\""
            },
            {
              "name":"queue",
              "type":"Bool",
              "fixedValuefixedValue":"true"
            }
          ],
          "parameterMapping":{
            "params":"[$parameters]",
            "method":"$altName"
          }
        },
        {
          "name":"broadcast",
          "path":"/transactions/broadcast",
          "method":"post",
          "task":"data",
          "parameters":[
            {
              "name":"data",
              "type":"Data"
            }
          ]
        },
        {
          "name":"transaction",
          "path":"transactions/info/{hash}",
          "method":"get",
          "task":"plain",
          "parameters":[
            {
              "name":"hash",
              "type":"String"
            }
          ]
        }
      ],
      "models":[
        {
          "name":"RippleAccount",
          "parameters":[
            {
              "name":"data",
              "outputName":"account_data",
              "type":"RippleAccountData"
            }
          ]
        },
        {
          "name":"RippleAccountData",
          "parameters":[
            {
              "name":"Balance",
              "type":"String"
            },
            {
              "name":"Sequence",
              "type":"Int64"
            }
          ]
        }
      ]
    }
}
    ```




## Notes
- Currently it doesn't support different names for the same input and parameter.
- It doesn't support custom headers for different endpoints.
