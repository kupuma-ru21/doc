```ts
import {useEffect, useRef, useState} from "react";

// isLiked is data from the server
type Props = {isLiked: boolean};

export const LikeButton: React.FC<Props> = ({isLiked}) => {
  const [isLikedOptimistic, setIsLikedOptimistic] = useState(isLiked);
  const debounceTimeout = useRef<NodeJS.Timeout | null>(null);
  const addLike = () => {
    // NOTE: Optimistic UI
    setIsLikedOptimistic(prev => !prev);
    // NOTE: Debounce to only send the request when the user stops clicking
    if (debounceTimeout.current) {
      clearTimeout(debounceTimeout.current);
    }
    debounceTimeout.current = setTimeout(() => {
      if (isLiked === isLikedOptimistic) {
        fetch("/endpoint", {
          method: "POST",
          body: JSON.stringify({
            // Something
          }),
        });
      }
    }, 500);
  };
  useEffect(() => {
    return () => {
      if (debounceTimeout.current) {
        clearTimeout(debounceTimeout.current);
      }
    };
  }, []);

  return <button onClick={addLike}></button>;
};
```
