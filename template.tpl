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
    "type": "CHECKBOX",
    "name": "storeResponseInCache",
    "checkboxText": "Store hashed value in cache",
    "simpleValueType": true,
    "defaultValue": true,
    "help": "Hashed values are cached to avoid unwanted additional network requests.",
    "subParams": [
      {
        "type": "TEXT",
        "name": "cacheExpirationTime",
        "displayName": "Cache Expiration Time",
        "simpleValueType": true,
        "defaultValue": 24,
        "valueValidators": [
          {
            "type": "NON_NEGATIVE_NUMBER"
          }
        ],
        "valueHint": "24",
        "valueUnit": "hours",
        "enablingConditions": [
          {
            "paramName": "storeResponseInCache",
            "paramValue": false,
            "type": "NOT_EQUALS"
          }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const createRegex = require('createRegex');
const encodeUriComponent = require('encodeUriComponent');
const getRequestHeader = require('getRequestHeader');
const getTimestampMillis = require('getTimestampMillis');
const getType = require('getType');
const JSON = require('JSON');
const makeNumber = require('makeNumber');
const makeString = require('makeString');
const sendHttpRequest = require('sendHttpRequest');
const sha256Sync = require('sha256Sync');
const templateDataStorage = require('templateDataStorage');
const testRegex = require('testRegex');

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
  const storeResponseInCache = data.hasOwnProperty('storeResponseInCache')
    ? data.storeResponseInCache
    : true;
  const cacheKey = storeResponseInCache ? sha256Sync(value) : undefined;
  if (storeResponseInCache) {
    const cacheExpirationTime = makeNumber(data.cacheExpirationTime || 24) * 60 * 60 * 1000;
    const cachedResultData = templateDataStorage.getItemCopy(cacheKey);
    if (cachedResultData && cachedResultData.ts + cacheExpirationTime > getTimestampMillis()) {
      return cachedResultData.hash;
    }
  }

  const requestUrl = getRequestUrl();
  const requestOptions = { method: 'POST', headers: { 'Content-Type': 'application/json' } };
  const requestBody = {
    value: value
  };

  return sendHttpRequest(requestUrl, requestOptions, JSON.stringify(requestBody))
    .then((result) => {
      if (result.statusCode >= 200 && result.statusCode < 300) {
        const hashedValue = JSON.parse(result.body).body.hash;
        if (storeResponseInCache) {
          templateDataStorage.setItemCopy(cacheKey, {
            hash: hashedValue,
            ts: getTimestampMillis()
          });
        }
        return hashedValue;
      }
    })
    .catch(() => {});
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
  if (valueType === 'null' || valueType === 'undefined' || value !== value) return false;
  return value !== '' && value !== 'undefined' && value !== 'null';
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
        "publicId": "access_template_storage",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
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
- name: Input value is not supported (undefined, null, empty, NaN, undefined or null
    string), should return undefined
  code: |-
    [undefined, null, '', 0 / 0, 'undefined', 'null'].forEach((value) => {
      mockData.inputValue = value;

      const variableResult = runCode(mockData);

      assertThat(variableResult).isUndefined();
      assertApi('sendHttpRequest').wasNotCalled();
    });
- name: Input value is already hashed, should return it
  code: |+
    const hashedInputValue = 'a132634601e37b7527daa6cbe1b401a1';
    mockData.inputValue = hashedInputValue;

    const variableResult = runCode(mockData);

    assertThat(variableResult).isDefined();
    assertThat(variableResult).isEqualTo(hashedInputValue);
    assertApi('sendHttpRequest').wasNotCalled();

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
    const expectedRequestOptions = { method: 'POST', headers: { 'Content-Type': 'application/json' } };
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
    const expectedRequestOptions = { method: 'POST', headers: { 'Content-Type': 'application/json' } };
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

    runCode(mockData).then((variableResult) => {
      assertThat(variableResult).isEqualTo(expectedHashedValue);
    });
- name: Request to the Stape API fails (network error), should return undefined
  code: |-
    mockData.inputValue = 'test@example.com';

    mock('getRequestHeader', () => 'header-mocked-value');

    mock('sendHttpRequest', () => {
      return Promise.create((resolve, reject) => {
        reject();
      });
    });

    runCode(mockData).then((variableResult) => {
      assertThat(variableResult).isUndefined();
    });
- name: Input value has a fresh cached hash, should return it without a request
  code: |-
    const NOW = 1000000000000;
    const expectedHashedValue = '55502f40dc8b7c769880b10874abc9d0';
    mockData.inputValue = 'test@example.com';

    mock('getTimestampMillis', () => NOW);
    mockObject('templateDataStorage', {
      getItemCopy: (key) => {
        assertThat(key).isEqualTo('sha256_' + mockData.inputValue);
        return { hash: expectedHashedValue, ts: NOW };
      },
      setItemCopy: (key, value) => {}
    });

    const variableResult = runCode(mockData);

    assertThat(variableResult).isEqualTo(expectedHashedValue);
    assertApi('sendHttpRequest').wasNotCalled();
- name: Input value has an expired cached hash, should make a request and return the
    fresh hash
  code: |-
    const JSON = require('JSON');
    const NOW = 1000000000000;
    const cacheDurationMs = 24 * 60 * 60 * 1000;
    const expectedHashedValue = '55502f40dc8b7c769880b10874abc9d0';
    mockData.inputValue = 'test@example.com';

    mock('getTimestampMillis', () => NOW);
    mock('getRequestHeader', () => 'header-mocked-value');
    mockObject('templateDataStorage', {
      getItemCopy: (key) => {
        return { hash: 'stale-hash-value', ts: NOW - cacheDurationMs };
      },
      setItemCopy: (key, value) => {}
    });

    mock('sendHttpRequest', () => {
      return Promise.create((resolve) => {
        resolve({
          statusCode: 200,
          body: JSON.stringify({ body: { hash: expectedHashedValue } })
        });
      });
    });

    runCode(mockData).then((variableResult) => {
      assertApi('sendHttpRequest').wasCalled();
      assertThat(variableResult).isEqualTo(expectedHashedValue);
    });
- name: Successful response is stored in template storage for future requests
  code: |-
    const JSON = require('JSON');
    const expectedHashedValue = '55502f40dc8b7c769880b10874abc9d0';
    mockData.inputValue = 'test@example.com';

    let storedKey;
    let storedValue;

    mock('getRequestHeader', () => 'header-mocked-value');
    mockObject('templateDataStorage', {
      getItemCopy: (key) => undefined,
      setItemCopy: (key, value) => {
        storedKey = key;
        storedValue = value;
      }
    });

    mock('sendHttpRequest', () => {
      return Promise.create((resolve) => {
        resolve({
          statusCode: 200,
          body: JSON.stringify({ body: { hash: expectedHashedValue } })
        });
      });
    });

    runCode(mockData).then(() => {
      assertThat(storedKey).isEqualTo('sha256_' + mockData.inputValue);
      assertThat(storedValue.hash).isEqualTo(expectedHashedValue);
      assertThat(storedValue.ts).isDefined();
    });
- name: storeResponseInCache is false, should not read or write the cache
  code: |-
    const JSON = require('JSON');
    const expectedHashedValue = '55502f40dc8b7c769880b10874abc9d0';
    mockData.inputValue = 'test@example.com';
    mockData.storeResponseInCache = false;

    let getItemCopyCalls = 0;
    let setItemCopyCalls = 0;

    mock('getRequestHeader', () => 'header-mocked-value');
    mockObject('templateDataStorage', {
      getItemCopy: (key) => {
        getItemCopyCalls++;
        return { hash: 'cached-hash-value', ts: 1000000000000 };
      },
      setItemCopy: (key, value) => {
        setItemCopyCalls++;
      }
    });

    mock('sendHttpRequest', () => {
      return Promise.create((resolve) => {
        resolve({
          statusCode: 200,
          body: JSON.stringify({ body: { hash: expectedHashedValue } })
        });
      });
    });

    runCode(mockData).then((variableResult) => {
      assertApi('sendHttpRequest').wasCalled();
      assertThat(getItemCopyCalls).isEqualTo(0);
      assertThat(setItemCopyCalls).isEqualTo(0);
      assertThat(variableResult).isEqualTo(expectedHashedValue);
    });
- name: Custom cache expiration time is respected when checking freshness
  code: |-
    const NOW = 1000000000000;
    const customCacheHours = 48;
    const staleUnderDefaultMs = 30 * 60 * 60 * 1000;
    const expectedHashedValue = '55502f40dc8b7c769880b10874abc9d0';
    mockData.inputValue = 'test@example.com';
    mockData.cacheExpirationTime = customCacheHours;

    mock('getTimestampMillis', () => NOW);
    mockObject('templateDataStorage', {
      getItemCopy: (key) => {
        return { hash: expectedHashedValue, ts: NOW - staleUnderDefaultMs };
      },
      setItemCopy: (key, value) => {}
    });

    const variableResult = runCode(mockData);

    assertThat(variableResult).isEqualTo(expectedHashedValue);
    assertApi('sendHttpRequest').wasNotCalled();
- name: Cache expiration time of 0 falls back to the default 24 hours
  code: |-
    const NOW = 1000000000000;
    const expectedHashedValue = '55502f40dc8b7c769880b10874abc9d0';
    mockData.inputValue = 'test@example.com';
    mockData.cacheExpirationTime = 0;

    mock('getTimestampMillis', () => NOW);
    mockObject('templateDataStorage', {
      getItemCopy: (key) => {
        return { hash: expectedHashedValue, ts: NOW };
      },
      setItemCopy: (key, value) => {}
    });

    const variableResult = runCode(mockData);

    assertThat(variableResult).isEqualTo(expectedHashedValue);
    assertApi('sendHttpRequest').wasNotCalled();
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

  mockObject('templateDataStorage', {
    getItemCopy: (key) => undefined,
    setItemCopy: (key, value) => {}
  });

  mock('sha256Sync', (value) => 'sha256_' + value);


___NOTES___

2026-09-18 Change Notes:
 - Add a Store hashed value in cache option (with a Cache Expiration Time sub-field, in hours) that stores hashed values in template storage, keyed by a SHA-256 digest of the input rather than the plaintext value, to avoid unwanted additional network requests.
 - Send a Content-Type: application/json header on the hash request to the Stape API.
 - Catch hash request failures (e.g. network errors) so the variable resolves to undefined instead of leaving the promise unhandled.
 - Treat NaN and the literal strings 'undefined'/'null' as invalid input, returning undefined instead of trying to hash them.
 - Order requires alphabetically.

2026-05-21 Change Notes:
 - Console logging removal.

Created on 4/14/2025, 1:48:32 PM

