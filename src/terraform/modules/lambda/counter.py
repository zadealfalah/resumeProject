import json
import boto3
import os

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ['DYNAMODB_TABLE_NAME']) # Env var in lambda/main.tf

def lambda_handler(event, context):
    try:
        # Retrieve the current view count
        response = table.get_item(Key={'id': '0'})
        
        # Initialize views to 0 if the item does not exist
        if 'Item' not in response:
            views = 0
        else:
            # Try converting the views to int
            views = int(response['Item']['views'])
        
        # Increment view count
        views += 1
        
        # Update the item in DynamoDB
        table.put_item(Item={'id': '0', 'views': views})
        
        # Return the updated view count
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Origin': 'https://zadealfalah.com',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
            # 'body': json.dumps(views) 
            'body': json.dumps({'visitorCount': views})
        }
    except (TypeError, ValueError, KeyError) as e:
        # Handle errors in conversion or accessing item
        print(f"Error processing item: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': f'Internal server error. {e}.  Views: {views}'})
        }
    