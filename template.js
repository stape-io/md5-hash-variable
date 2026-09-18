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
