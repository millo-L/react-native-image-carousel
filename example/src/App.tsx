import { useMemo, useRef, useState } from 'react';
import { StyleSheet, ScrollView, TouchableOpacity, Text } from 'react-native';
import RNImageCarousel, {
  type RNImageCarouselRef,
} from '@millo-l/react-native-image-carousel';

export default function App() {
  const ref = useRef<RNImageCarouselRef>(null);
  const [index, setIndex] = useState<number>(0);
  const data = useMemo(
    () =>
      [
        'https://picsum.photos/id/237/536/354',
        'https://picsum.photos/seed/picsum/536/354',
        'https://picsum.photos/id/1084/536/354?grayscale',
        'https://picsum.photos/id/1060/536/354?blur=2',
        'https://picsum.photos/id/870/536/354?grayscale&blur=2',
      ].map((url) => ({ imgUrl: url })),
    []
  );

  return (
    <ScrollView style={styles.container}>
      <RNImageCarousel
        ref={ref}
        data={data}
        style={styles.carousel}
        autoPlay
        interval={1500}
        onPressImage={console.log}
        onChangeIndex={setIndex}
      />
      <TouchableOpacity onPress={() => ref.current?.scrollToIndex(2)}>
        <Text>click: scrollToIndex(2)</Text>
      </TouchableOpacity>
      <Text>currentIndex: {index}</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  carousel: {
    width: '100%',
    height: 300,
    backgroundColor: 'green',
    borderRadius: 20,
    overflow: 'hidden',
  },
});
