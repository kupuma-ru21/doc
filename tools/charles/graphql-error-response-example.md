- REF: https://www.apollographql.com/docs/react/data/error-handling

```
{
  "errors": [
    {
      "message": "Cannot query field \"nonexistentField\" on type \"Query\".",
      "locations": [
        {
          "line": 2,
          "column": 3
        }
      ],
      "extensions": {
        "code": "GRAPHQL_VALIDATION_FAILED",
        "exception": {
          "stacktrace": [
            "GraphQLError: Cannot query field \"nonexistentField\" on type \"Query\".",
            "...additional lines..."
          ]
        }
      }
    }
  ],
  "data": null
}
```
