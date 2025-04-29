# LocalとProdで挙動が一致しない

- LocalとProdで挙動が一致しない事象が発生
  具体的にはgraphqlでresponse取得するためにqueryを実行
  queryを実行時にwhereを指定
  whereの中にcreatedAtがある
  createdAtの値は`const createdAt = dayjs().utc()`
  createdAtは定数なので、値はbuild時の日付になる
  期待値としてcreatedAtは実行時の日付
  結果、乖離が発生
  createdAtの値を実行時の日付として扱うために、`const getCreatedAt = () => dayjs().utc();`に変更
