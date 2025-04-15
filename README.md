# MD5 Hash Variable for Google Tag Manager Server Container

The **MD5 Hash Variable** for Google Tag Manager Server Container allows you to generate the MD5 hash of an input value. This is useful for applications that require hashed data, such as when storing sensitive data or working with encrypted data.

## Getting Started

1. **Add the MD5 Hash Variable** to your GTM Server container.
2. **Configure the Required Parameter**:
   - **Value to be Hashed**: Enter the value that you want to hash using the MD5 algorithm.
3. **Logging Options**:
   - **Console Logging**: Control whether logs should be displayed in the console during debugging or production.
   - **BigQuery Logging**: Optionally log hash-related data to Google BigQuery for further analysis (requires BigQuery setup).

## Parameters

- **Value to be Hashed**: The string or value you want to convert to an MD5 hash.

## Example Input & Output

- **Input**: `test@example.com`
- **Output**: `55502f40dc8b7c769880b10874abc9d0` (MD5 hash of the input)

## Open Source

The **MD5 Hash Variable** for GTM Server is developed and maintained by the [Stape Team](https://stape.io/) under the Apache 2.0 license.
