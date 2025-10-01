# Postman Collections for Messaging Service

This directory contains Postman collections for testing the messaging service API.

## Files

- `messaging-service-collections.json` - Complete Postman collection with success and failure test cases

## How to Use

### 1. Import into Postman

1. Open Postman
2. Click "Import" button
3. Select `messaging-service-collections.json`
4. The collection will be imported with two folders:
   - ✅ **Success Tests** - Tests that should return 200 status codes
   - ❌ **Expected Fail Tests** - Tests that should return error status codes (400, 404, 500)

### 2. Set Environment Variables

The collection uses a `baseUrl` variable that defaults to `http://localhost:8080`. You can:

- Use the default value for local testing
- Create a Postman environment to override the baseUrl for different environments
- Change the variable value directly in the collection

### 3. Running Tests

#### Individual Tests
- Click on any request in the collection
- Click "Send" to execute the request
- Check the response status code and body

#### Collection Runner
1. Right-click on the collection name
2. Select "Run collection"
3. Choose which tests to run
4. Click "Run" to execute all selected tests

#### Newman (Command Line)
```bash
# Install Newman
npm install -g newman

# Run the collection
newman run messaging-service-collections.json

# Run with environment
newman run messaging-service-collections.json -e environment.json

# Run with custom base URL
newman run messaging-service-collections.json --env-var "baseUrl=http://localhost:3000"
```

## Test Categories

### ✅ Success Tests (Expected 200 Status)

1. **Health Check** - Verify service is running
2. **Send SMS** - Send a valid SMS message
3. **Send MMS** - Send a valid MMS message with attachment
4. **Send Email** - Send a valid email with HTML content
5. **Incoming SMS Webhook** - Simulate incoming SMS from provider
6. **Incoming MMS Webhook** - Simulate incoming MMS from provider
7. **Incoming Email Webhook** - Simulate incoming email from provider
8. **Get All Conversations** - Retrieve all conversations
9. **Get Messages for Conversation** - Retrieve messages for specific conversation

### ❌ Expected Fail Tests (Expected Error Status)

1. **Missing 'from' Field** - Test missing required field (400)
2. **Missing 'to' Field** - Test missing required field (400)
3. **Missing 'type' Field** - Test missing required field (400)
4. **Missing 'messaging_provider_id' Field** - Test missing required field (400)
5. **Missing 'body' Field** - Test missing required field (400)
6. **Missing 'timestamp' Field** - Test missing required field (400)
7. **Invalid Message Type** - Test invalid message type (400)
8. **Empty Required Fields** - Test empty string values (400)
9. **Email Webhook Missing 'xillio_id'** - Test missing email-specific field (400)
10. **Invalid JSON Format** - Test malformed JSON (500)
11. **SMS Data to Email Endpoint** - Test wrong endpoint usage (400)
12. **Non-existent Conversation Messages** - Test invalid conversation ID (404)

## Prerequisites

Before running the tests:

1. **Start the messaging service**:
   ```bash
   ./bin/start
   ```

2. **Verify service is running**:
   ```bash
   curl http://localhost:8080/health
   ```

3. **Optional: Clear database** (for clean test runs):
   ```bash
   ./bin/db-clear --confirm
   ```

## Expected Results

### Success Tests
- All should return **200 OK** status
- Response bodies should contain success messages or data
- Database should be updated with new conversations/messages

### Failure Tests
- Should return appropriate error status codes:
  - **400 Bad Request** for validation errors
  - **404 Not Found** for missing resources
  - **500 Internal Server Error** for server errors
- Response bodies should contain error messages

## Troubleshooting

### Service Not Running
```
Error: connect ECONNREFUSED 127.0.0.1:8080
```
**Solution**: Start the service with `./bin/start`

### Database Connection Issues
```
Error: Database connection failed
```
**Solution**: Check if PostgreSQL container is running with `docker-compose ps`

### Port Already in Use
```
Error: bind: address already in use
```
**Solution**: Stop other services on port 8080 or change the port in the collection

## Integration with CI/CD

You can integrate these Postman collections into your CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Run API Tests
  run: |
    npm install -g newman
    newman run bin/postman/messaging-service-collections.json \
      --env-var "baseUrl=http://localhost:8080" \
      --reporters cli,json \
      --reporter-json-export test-results.json
```

## Customization

### Adding New Tests
1. Open the collection in Postman
2. Add new requests to the appropriate folder (Success or Expected Fail)
3. Set the expected status code in the test description
4. Export the updated collection

### Environment Variables
Create environment-specific configurations:
- `local` - http://localhost:8080
- `staging` - https://staging-api.example.com
- `production` - https://api.example.com

### Test Scripts
Add Postman test scripts to validate responses:
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has required fields", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('status');
    pm.expect(jsonData).to.have.property('message');
});
```

## Support

For issues with the Postman collections:
1. Check the service logs: `docker-compose logs messaging-service`
2. Verify the service is running: `curl http://localhost:8080/health`
3. Check the database: `./bin/db-inspect`

