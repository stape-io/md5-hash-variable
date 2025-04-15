___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "MD5 Hash",
  "description": "Produces the MD5 hash of the input value. This variable works only for Stape-hosted GTM containers.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "inputValue",
    "displayName": "Value to be hashed",
    "simpleValueType": true,
    "help": "Enter the value to be MD5 hashed.\u003cbr/\u003eObs.: this variable works only for Stape-hosted GTM containers.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "displayName": "Logs Settings",
    "name": "logsGroup",
    "groupStyle": "ZIPPY_CLOSED",
    "type": "GROUP",
    "subParams": [
      {
        "type": "RADIO",
        "name": "logType",
        "radioItems": [
          {
            "value": "no",
            "displayValue": "Do not log"
          },
          {
            "value": "debug",
            "displayValue": "Log to console during debug and preview"
          },
          {
            "value": "always",
            "displayValue": "Always log to console"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "debug"
      }
    ]
  },
  {
    "displayName": "BigQuery Logs Settings",
    "name": "bigQueryLogsGroup",
    "groupStyle": "ZIPPY_CLOSED",
    "type": "GROUP",
    "subParams": [
      {
        "type": "RADIO",
        "name": "bigQueryLogType",
        "radioItems": [
          {
            "value": "no",
            "displayValue": "Do not log to BigQuery"
          },
          {
            "value": "always",
            "displayValue": "Log to BigQuery"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "no"
      },
      {
        "type": "GROUP",
        "name": "logsBigQueryConfigGroup",
        "groupStyle": "NO_ZIPPY",
        "subParams": [
          {
            "type": "TEXT",
            "name": "logBigQueryProjectId",
            "displayName": "BigQuery Project ID",
            "simpleValueType": true,
            "help": "Optional.  \u003cbr\u003e\u003cbr\u003e  If omitted, it will be retrieved from the environment variable \u003cI\u003eGOOGLE_CLOUD_PROJECT\u003c/i\u003e where the server container is running. If the server container is running on Google Cloud, \u003cI\u003eGOOGLE_CLOUD_PROJECT\u003c/i\u003e will already be set to the Google Cloud project\u0027s ID."
          },
          {
            "type": "TEXT",
            "name": "logBigQueryDatasetId",
            "displayName": "BigQuery Dataset ID",
            "simpleValueType": true,
            "valueValidators": [
              {
                "type": "NON_EMPTY"
              }
            ]
          },
          {
            "type": "TEXT",
            "name": "logBigQueryTableId",
            "displayName": "BigQuery Table ID",
            "simpleValueType": true,
            "valueValidators": [
              {
                "type": "NON_EMPTY"
              }
            ]
          }
        ],
        "enablingConditions": [
          {
            "paramName": "bigQueryLogType",
            "paramValue": "always",
            "type": "EQUALS"
          }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const getType = require('getType');
const encodeUriComponent = require('encodeUriComponent');
const makeString = require('makeString');
const getRequestHeader = require('getRequestHeader');
const createRegex = require('createRegex');
const testRegex = require('testRegex');
const sendHttpRequest = require('sendHttpRequest');
const JSON = require('JSON');
const logToConsole = require('logToConsole');
const getContainerVersion = require('getContainerVersion');
const BigQuery = require('BigQuery');
const getTimestampMillis = require('getTimestampMillis');

/**********************************************************************************************/

const traceId = getRequestHeader('trace-id');

let inputValue = data.inputValue;

if (!isValidValue(inputValue)) return;

inputValue = makeString(inputValue);

if (isMD5Hash(inputValue)) return inputValue;

return hash(inputValue);

/**********************************************************************************************/

function hash(value) {
  const requestUrl = getRequestUrl();
  const requestBody = {
    value: value
  };

  log({
    Name: 'MD5 Hash',
    Type: 'Request',
    TraceId: traceId,
    EventName: 'hash',
    RequestMethod: 'POST',
    RequestUrl: requestUrl,
    RequestBody: requestBody
  });

  return sendHttpRequest(
    requestUrl,
    { method: 'POST' },
    JSON.stringify(requestBody)
  ).then((result) => {
    log({
      Name: 'MD5 Hash',
      Type: 'Response',
      TraceId: traceId,
      EventName: 'hash',
      ResponseStatusCode: result.statusCode,
      ResponseHeaders: result.headers,
      ResponseBody: result.body
    });

    if (result.statusCode >= 200 && result.statusCode < 300) {
      const hashedValue = JSON.parse(result.body).body.hash;
      return hashedValue;
    }
  });
}

function getRequestUrl() {
  const containerIdentifier = getRequestHeader('x-gtm-identifier');
  const defaultDomain = getRequestHeader('x-gtm-default-domain');
  const containerApiKey = getRequestHeader('x-gtm-api-key');

  return (
    'https://' +
    enc(containerIdentifier) +
    '.' +
    enc(defaultDomain) +
    '/stape-api/' +
    enc(containerApiKey) +
    '/v1/hash/md5'
  );
}

/**********************************************************************************************/
// Helpers

function isValidValue(value) {
  const valueType = getType(value);
  return valueType !== 'null' && valueType !== 'undefined' && value !== '';
}

function isMD5Hash(str) {
  const md5Regex = createRegex('^[a-f0-9]{32}$', 'i');
  return testRegex(md5Regex, str);
}

function enc(data) {
  return encodeUriComponent(data || '');
}

function log(rawDataToLog) {
  const logDestinationsHandlers = {};
  if (determinateIsLoggingEnabled())
    logDestinationsHandlers.console = logConsole;
  if (determinateIsLoggingEnabledForBigQuery())
    logDestinationsHandlers.bigQuery = logToBigQuery;

  // Key mappings for each log destination
  const keyMappings = {
    // No transformation for Console is needed.
    bigQuery: {
      Name: 'tag_name',
      Type: 'type',
      TraceId: 'trace_id',
      EventName: 'event_name',
      RequestMethod: 'request_method',
      RequestUrl: 'request_url',
      RequestBody: 'request_body',
      ResponseStatusCode: 'response_status_code',
      ResponseHeaders: 'response_headers',
      ResponseBody: 'response_body'
    }
  };

  for (const logDestination in logDestinationsHandlers) {
    const handler = logDestinationsHandlers[logDestination];
    if (!handler) continue;

    const mapping = keyMappings[logDestination];
    const dataToLog = mapping ? {} : rawDataToLog;
    // Map keys based on the log destination
    if (mapping) {
      for (const key in rawDataToLog) {
        const mappedKey = mapping[key] || key; // Fallback to original key if no mapping exists
        dataToLog[mappedKey] = rawDataToLog[key];
      }
    }

    handler(dataToLog);
  }
}

function logConsole(dataToLog) {
  logToConsole(JSON.stringify(dataToLog));
}

function logToBigQuery(dataToLog) {
  const connectionInfo = {
    projectId: data.logBigQueryProjectId,
    datasetId: data.logBigQueryDatasetId,
    tableId: data.logBigQueryTableId
  };

  // timestamp is required.
  dataToLog.timestamp = getTimestampMillis();

  // Columns with type JSON need to be stringified.
  ['request_body', 'response_headers', 'response_body'].forEach((p) => {
    // GTM Sandboxed JSON.parse returns undefined for malformed JSON but throws post-execution, causing execution failure.
    // If fixed, could use: dataToLog[p] = JSON.stringify(JSON.parse(dataToLog[p]) || dataToLog[p]);
    dataToLog[p] = JSON.stringify(dataToLog[p]);
  });

  // assertApi doesn't work for 'BigQuery.insert()'. It's needed to convert BigQuery into a function when testing.
  // Ref: https://gtm-gear.com/posts/gtm-templates-testing/
  const bigquery =
    getType(BigQuery) === 'function'
      ? BigQuery() /* Only during Unit Tests */
      : BigQuery;
  bigquery.insert(connectionInfo, [dataToLog], { ignoreUnknownValues: true });
}

function determinateIsLoggingEnabled() {
  const containerVersion = getContainerVersion();
  const isDebug = !!(
    containerVersion &&
    (containerVersion.debugMode || containerVersion.previewMode)
  );

  if (!data.logType) {
    return isDebug;
  }

  if (data.logType === 'no') {
    return false;
  }

  if (data.logType === 'debug') {
    return isDebug;
  }

  return data.logType === 'always';
}

function determinateIsLoggingEnabledForBigQuery() {
  if (data.bigQueryLogType === 'no') return false;
  return data.bigQueryLogType === 'always';
}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "headerWhitelist",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "trace-id"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "x-gtm-identifier"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "x-gtm-default-domain"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "x-gtm-api-key"
                  }
                ]
              }
            ]
          }
        },
        {
          "key": "headersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "all"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_bigquery",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedTables",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "projectId"
                  },
                  {
                    "type": 1,
                    "string": "datasetId"
                  },
                  {
                    "type": 1,
                    "string": "tableId"
                  },
                  {
                    "type": 1,
                    "string": "operation"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Input value is not supported (undefined, null, ''), should return undefined
  code: |-
    [undefined, null, ''].forEach((value) => {
      mockData.inputValue = value;

      const variableResult = runCode(mockData);

      assertThat(variableResult).isUndefined();
    });
- name: Input value is already hashed, should return it
  code: |
    const hashedInputValue = 'a132634601e37b7527daa6cbe1b401a1';
    mockData.inputValue = hashedInputValue;

    const variableResult = runCode(mockData);

    assertThat(variableResult).isDefined();
    assertThat(variableResult).isEqualTo(hashedInputValue);
- name: Input value is valid, but this Stape account DOES NOT support MD5 hashing
    through this endpoint, should return undefined
  code: "const JSON = require('JSON');\n\nmockData.inputValue = 'test@example.com';\n\
    const expectedHashedValue = '55502f40dc8b7c769880b10874abc9d0';\n\nconst expectedXGtmHeadersValue\
    \ = 'xgtm';\nconst expectedXGtmHeaders = {\n  'x-gtm-identifier': expectedXGtmHeadersValue,\n\
    \  'x-gtm-default-domain': expectedXGtmHeadersValue,\n  'x-gtm-api-key': expectedXGtmHeadersValue\n\
    };\n\nconst expectedRequestUrl = 'https://' + expectedXGtmHeaders['x-gtm-identifier']\
    \ + '.' + expectedXGtmHeaders['x-gtm-default-domain'] + '/stape-api/' + expectedXGtmHeaders['x-gtm-api-key']\
    \ + '/v1/hash/md5';\nconst expectedRequestOptions = { method: 'POST' };\nconst\
    \ expectedRequestBody = JSON.stringify({ value: mockData.inputValue });\n\nmock('getRequestHeader',\
    \ (header) => {\n  switch (header) {\n    case 'x-gtm-identifier':\n    case 'x-gtm-default-domain':\n\
    \    case 'x-gtm-api-key':\n      return expectedXGtmHeaders[header];\n    default:\n\
    \      return 'header-mocked-value';\n  }\n});\n\nmock('sendHttpRequest', (requestUrl,\
    \ requestOptions, requestBody) => {\n  assertThat(requestUrl).isEqualTo(expectedRequestUrl);\n\
    \  assertThat(requestOptions).isEqualTo(expectedRequestOptions);\n  assertThat(requestBody).isEqualTo(expectedRequestBody);\n\
    \  return { \n    then: (callback) => {\n      const result = {\n        statusCode:\
    \ 404,\n        body: \"{\\\"body\\\":[],\\\"error\\\":{\\\"code\\\":404,\\\"\
    message\\\":\\\"No route found for \\\\\\\"POST https:\\\\/\\\\/foobar.stape.net\\\
    \\/stape-api\\\\/123456789foobar\\\\/v1\\\\/hash\\\\/md5\\\\\\\"\\\"}}\"\n   \
    \   };\n      \n      return callback(result);\n    } \n  };\n});\n\nconst variableResult\
    \ = runCode(mockData);\n\nassertThat(variableResult).isUndefined();"
- name: Input value is valid, and the Stape account supports MD5 hashing through this
    endpoint, should return the hashed value
  code: "const JSON = require('JSON');\n\nmockData.inputValue = 'test@example.com';\n\
    const expectedHashedValue = '55502f40dc8b7c769880b10874abc9d0';\n\nconst expectedXGtmHeadersValue\
    \ = 'xgtm';\nconst expectedXGtmHeaders = {\n  'x-gtm-identifier': expectedXGtmHeadersValue,\n\
    \  'x-gtm-default-domain': expectedXGtmHeadersValue,\n  'x-gtm-api-key': expectedXGtmHeadersValue\n\
    };\n\nconst expectedRequestUrl = 'https://' + expectedXGtmHeaders['x-gtm-identifier']\
    \ + '.' + expectedXGtmHeaders['x-gtm-default-domain'] + '/stape-api/' + expectedXGtmHeaders['x-gtm-api-key']\
    \ + '/v1/hash/md5';\nconst expectedRequestOptions = { method: 'POST' };\nconst\
    \ expectedRequestBody = JSON.stringify({ value: mockData.inputValue });\n\nmock('getRequestHeader',\
    \ (header) => {\n  switch (header) {\n    case 'x-gtm-identifier':\n    case 'x-gtm-default-domain':\n\
    \    case 'x-gtm-api-key':\n      return expectedXGtmHeaders[header];\n    default:\n\
    \      return 'header-mocked-value';\n  }\n});\n\nmock('sendHttpRequest', (requestUrl,\
    \ requestOptions, requestBody) => {\n  assertThat(requestUrl).isEqualTo(expectedRequestUrl);\n\
    \  assertThat(requestOptions).isEqualTo(expectedRequestOptions);\n  assertThat(requestBody).isEqualTo(expectedRequestBody);\n\
    \  return { \n    then: (callback) => {\n      const result = {\n        statusCode:\
    \ 200,\n        body: JSON.stringify({ body: { hash: expectedHashedValue, value:\
    \ mockData.inputValue } })\n      };\n      \n      return callback(result);\n\
    \    } \n  };\n});\n\nconst variableResult = runCode(mockData);\n\nassertThat(variableResult).isEqualTo(expectedHashedValue);"
setup: const mockData = {};


___NOTES___

Created on 4/14/2025, 1:48:32 PM

