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

/*==============================================================================
==============================================================================*/

let inputValue = data.inputValue;

if (!isValidValue(inputValue)) return;

inputValue = makeString(inputValue);

if (isMD5Hash(inputValue)) return inputValue;
return hash(inputValue);

/*==============================================================================
==============================================================================*/

function hash(value) {
  const requestUrl = getRequestUrl();
  const requestBody = {
    value: value
  };

  return sendHttpRequest(requestUrl, { method: 'POST' }, JSON.stringify(requestBody)).then(
    (result) => {
      if (result.statusCode >= 200 && result.statusCode < 300) {
        const hashedValue = JSON.parse(result.body).body.hash;
        return hashedValue;
      }
    }
  );
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

/*==============================================================================
  Helpers
==============================================================================*/

function isValidValue(value) {
  const valueType = getType(value);
  return valueType !== 'null' && valueType !== 'undefined' && value !== '' && value === value;
}

function isMD5Hash(str) {
  const md5Regex = createRegex('^[a-f0-9]{32}$', 'i');
  return testRegex(md5Regex, str);
}

function enc(data) {
  if (['null', 'undefined'].indexOf(getType(data)) !== -1) data = '';
  return encodeUriComponent(makeString(data));
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
  code: |-
    const JSON = require('JSON');

    mockData.inputValue = 'test@example.com';
    const expectedHashedValue = '55502f40dc8b7c769880b10874abc9d0';

    const expectedXGtmHeadersValue = 'xgtm';
    const expectedXGtmHeaders = {
      'x-gtm-identifier': expectedXGtmHeadersValue,
      'x-gtm-default-domain': expectedXGtmHeadersValue,
      'x-gtm-api-key': expectedXGtmHeadersValue
    };

    const expectedRequestUrl = 'https://' + expectedXGtmHeaders['x-gtm-identifier'] + '.' + expectedXGtmHeaders['x-gtm-default-domain'] + '/stape-api/' + expectedXGtmHeaders['x-gtm-api-key'] + '/v1/hash/md5';
    const expectedRequestOptions = { method: 'POST' };
    const expectedRequestBody = JSON.stringify({ value: mockData.inputValue });

    mock('getRequestHeader', (header) => {
      switch (header) {
        case 'x-gtm-identifier':
        case 'x-gtm-default-domain':
        case 'x-gtm-api-key':
          return expectedXGtmHeaders[header];
        default:
          return 'header-mocked-value';
      }
    });

    mock('sendHttpRequest', (requestUrl, requestOptions, requestBody) => {
      assertThat(requestUrl).isEqualTo(expectedRequestUrl);
      assertThat(requestOptions).isEqualTo(expectedRequestOptions);
      assertThat(requestBody).isEqualTo(expectedRequestBody);
      return Promise.create((resolve) => {
        resolve({
          statusCode: 404,
          body: "{\"body\":[],\"error\":{\"code\":404,\"message\":\"No route found for \\\"POST https:\\/\\/foobar.stape.net\\/stape-api\\/123456789foobar\\/v1\\/hash\\/md5\\\"\"}}"
        });
      });
    });

    runCode(mockData).then((variableResult) => {
      assertThat(variableResult).isUndefined();
    });
- name: Input value is valid, and the Stape account supports MD5 hashing through this
    endpoint, should return the hashed value
  code: |-
    const JSON = require('JSON');

    mockData.inputValue = 'test@example.com';
    const expectedHashedValue = '55502f40dc8b7c769880b10874abc9d0';

    const expectedXGtmHeadersValue = 'xgtm';
    const expectedXGtmHeaders = {
      'x-gtm-identifier': expectedXGtmHeadersValue,
      'x-gtm-default-domain': expectedXGtmHeadersValue,
      'x-gtm-api-key': expectedXGtmHeadersValue
    };

    const expectedRequestUrl = 'https://' + expectedXGtmHeaders['x-gtm-identifier'] + '.' + expectedXGtmHeaders['x-gtm-default-domain'] + '/stape-api/' + expectedXGtmHeaders['x-gtm-api-key'] + '/v1/hash/md5';
    const expectedRequestOptions = { method: 'POST' };
    const expectedRequestBody = JSON.stringify({ value: mockData.inputValue });

    mock('getRequestHeader', (header) => {
      switch (header) {
        case 'x-gtm-identifier':
        case 'x-gtm-default-domain':
        case 'x-gtm-api-key':
          return expectedXGtmHeaders[header];
        default:
          return 'header-mocked-value';
      }
    });

    mock('sendHttpRequest', (requestUrl, requestOptions, requestBody) => {
      assertThat(requestUrl).isEqualTo(expectedRequestUrl);
      assertThat(requestOptions).isEqualTo(expectedRequestOptions);
      assertThat(requestBody).isEqualTo(expectedRequestBody);
      return Promise.create((resolve) => {
        resolve({
          statusCode: 200,
          body: JSON.stringify({ body: { hash: expectedHashedValue, value: mockData.inputValue } })
        });
      });
    });

    const variableResult = runCode(mockData);

    runCode(mockData).then((variableResult) => {
      assertThat(variableResult).isEqualTo(expectedHashedValue);
    });
setup: |-
  const Promise = require('Promise');

  const mockData = {};

  mock('sendHttpRequest', (requestUrl, requestOptions, requestBody) => {
    return Promise.create((resolve) => {
      resolve({
        statusCode: 404,
        body: "{\"body\":[],\"error\":{\"code\":404,\"message\":\"No route found for \\\"POST https:\\/\\/foobar.stape.net\\/stape-api\\/123456789foobar\\/v1\\/hash\\/md5\\\"\"}}"
      });
    });
  });


___NOTES___

2026-05-21 Change Notes:
 - Console logging removal.

Created on 4/14/2025, 1:48:32 PM
