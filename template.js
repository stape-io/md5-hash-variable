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

    if (mapping) {
      for (const key in rawDataToLog) {
        const mappedKey = mapping[key] || key;
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

  dataToLog.timestamp = getTimestampMillis();

  ['request_body', 'response_headers', 'response_body'].forEach((p) => {
    dataToLog[p] = JSON.stringify(dataToLog[p]);
  });

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
