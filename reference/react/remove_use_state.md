```ts
import {useRef} from "react";

export const Component: React.FC = () => {
  const fieldsetRef = useRef<HTMLFieldSetElement>(null);
  return (
    <>
      <input
        onChange={e => {
          if (fieldsetRef.current === null) return;
          fieldsetRef.current.disabled = e.target.value === "";
        }}
      />
      <fieldset disabled ref={fieldsetRef}>
        <button onClick={() => console.log("button clicked")}>button</button>
      </fieldset>
    </>
  );
};

```
