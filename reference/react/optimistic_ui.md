```ts
import {useEffect, useRef, useState} from "react";
import {useMutation} from "@apollo/client/react/hooks";
import {getContext} from "@app/utils/graphql";
import {
  CreateLikeEpisodeCommentDocument,
  DeleteLikeEpisodeCommentDocument,
} from "@gql/graphql";

type Props = {isLiked: boolean; commentId: string; token: string};

export const LikeButton: React.FC<Props> = ({isLiked, commentId, token}) => {
  const [createLikeEpisodeComment] = useMutation(
    CreateLikeEpisodeCommentDocument,
    {context: getContext(token), variables: {episodeCommentId: commentId}}
  );
  const [deleteLikeEpisodeComment] = useMutation(
    DeleteLikeEpisodeCommentDocument,
    {context: getContext(token), variables: {episodeCommentId: commentId}}
  );

  const [isLikedOptimistic, setIsLikedOptimistic] = useState(isLiked);
  const debounceTimeout = useRef<NodeJS.Timeout | null>(null);
  const isOptimisticLikedRef = useRef(isLiked);
  const addLike = () => {
    setIsLikedOptimistic(prev => !prev);
    if (debounceTimeout.current) {
      clearTimeout(debounceTimeout.current);
    }
    debounceTimeout.current = setTimeout(() => {
      if (isOptimisticLikedRef.current !== isLikedOptimistic) return;
      if (isLikedOptimistic) {
        deleteLikeEpisodeComment();
        isOptimisticLikedRef.current = false;
      } else {
        createLikeEpisodeComment();
        isOptimisticLikedRef.current = true;
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

  return <button onClick={addLike}>like</button>;
};

```
