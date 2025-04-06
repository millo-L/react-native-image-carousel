import React, {
  forwardRef,
  useCallback,
  useImperativeHandle,
  useMemo,
} from 'react';
import {
  requireNativeComponent,
  UIManager,
  findNodeHandle,
  type ViewProps,
  type ImageRequireSource,
  Image,
} from 'react-native';

type NativeProps = ViewProps & {
  data: string[];
  autoPlay?: boolean;
  interval?: number;
  onPressImage?: (e: { nativeEvent: { index: number } }) => void;
  onChangeIndex?: (e: { nativeEvent: { index: number } }) => void;
};

export type RNImageCarouselRef = {
  scrollToIndex: (index: number) => void;
};

const COMPONENT_NAME = 'ImageCarousel';

const NativeImageCarousel = requireNativeComponent<NativeProps>(COMPONENT_NAME);

type CarouselProps<T extends { imgUrl: string | ImageRequireSource }> =
  ViewProps & {
    data: T[];
    autoPlay?: boolean;
    interval?: number;
    onPressImage?: (item: T) => void;
    onChangeIndex?: (index: number) => void;
  };

const RNImageCarousel = forwardRef(
  <T extends { imgUrl: string | ImageRequireSource }>(
    props: CarouselProps<T>,
    ref: React.Ref<RNImageCarouselRef>
  ) => {
    const nativeRef = React.useRef(null);

    const urls = useMemo(
      () =>
        props.data.map((item) =>
          typeof item.imgUrl === 'string'
            ? item.imgUrl
            : Image.resolveAssetSource(item.imgUrl).uri
        ),
      [props.data]
    );

    const handlePressImage = useCallback(
      (e: { nativeEvent: { index: number } }) => {
        const index = e.nativeEvent.index;
        const item = props.data[index];
        if (props.onPressImage && item) {
          props.onPressImage(item);
        }
      },
      [props]
    );

    const handleChangeIndex = useCallback(
      (e: { nativeEvent: { index: number } }) => {
        const index = e.nativeEvent.index;
        if (props.onChangeIndex) {
          props.onChangeIndex(index);
        }
      },
      [props]
    );

    useImperativeHandle(ref, () => ({
      scrollToIndex: (index: number) => {
        const nodeHandle = findNodeHandle(nativeRef.current);
        if (!nodeHandle) return;

        UIManager.dispatchViewManagerCommand(
          nodeHandle,
          // RN 0.76 이상에서는 getViewManagerConfig 제거됨
          UIManager.getViewManagerConfig
            ? UIManager.getViewManagerConfig(COMPONENT_NAME).Commands
                .scrollToIndex
            : (UIManager as any)[COMPONENT_NAME].Commands.scrollToIndex,
          [index]
        );
      },
    }));

    return (
      <NativeImageCarousel
        {...props}
        ref={nativeRef}
        data={urls}
        onPressImage={handlePressImage}
        onChangeIndex={handleChangeIndex}
      />
    );
  }
) as <T extends { imgUrl: string | ImageRequireSource }>(
  props: CarouselProps<T> & { ref?: React.Ref<RNImageCarouselRef> }
) => React.ReactElement;

export default RNImageCarousel;
