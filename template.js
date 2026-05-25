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
