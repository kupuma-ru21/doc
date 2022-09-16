module.exports = {
  rules: {
    "no-restricted-syntax": [
      "error",
      {
        "selector": "JSXElement > JSXExpressionContainer > LogicalExpression[operator!='??'][operator!='||']",
        "message": "Please use ternary operator instead"
      }
    ],
    // type Omitted<T, K extends keyof T> = Pick<T, Exclude<keyof T, K>>;
    '@typescript-eslint/ban-types': ['error', { types: { Omit: "Please use Omitted`" } }],
  },
};
