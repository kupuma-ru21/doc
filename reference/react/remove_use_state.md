```:js
import {useRef} from "react";

export const Component: React.FC = () => {
  const fieldsetRef = useRef<HTMLFieldSetElement>(null);
  return (
    <>
      <input
        onChange={e => {
          if (e.target.value === "") {
            fieldsetRef.current?.setAttribute("disabled", "");
          } else {
            fieldsetRef.current?.removeAttribute("disabled");
          }
        }}
      />
      <fieldset disabled ref={fieldsetRef}>
        <button onClick={() => console.log("button clicked")}>button</button>
      </fieldset>
    </>
  );
};
```
