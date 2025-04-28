# VSCodeのExtensionが動かない

- [vscode-eslint](https://github.com/microsoft/vscode-eslint)が動かなくなった
  FYI: vscode-eslintはnode_modules直下のmoduleを参照する

- VSCode > OUTPUT > Eslintを選択すると、logが見れる
  log内容は以下
  ```
  Error: Failed to load plugin 'n' declared in ' » ./node_modules/gts': Cannot find module 'eslint-plugin-n'™
  ```
  これはnode_modules**直下**に'eslint-plugin-n'が存在しないので、参照できないことを意味してる
  なので、node_modules**直下**に'eslint-plugin-n'が存在する必要がある
  node_modules**直下**に'eslint-plugin-n'が存在させる方法は以下
  https://github.com/microsoft/vscode-eslint/issues/1986#issuecomment-2799868163
