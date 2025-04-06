import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';

// Mock the native module
jest.mock('react-native', () => ({
  requireNativeComponent: jest.fn(() => 'NativeImageCarousel'),
  UIManager: {
    getViewManagerConfig: jest.fn(() => ({
      Commands: {
        scrollToIndex: 'scrollToIndex',
      },
    })),
    dispatchViewManagerCommand: jest.fn(),
  },
  findNodeHandle: jest.fn(() => 123),
  View: 'View',
  Text: 'Text',
  ScrollView: 'ScrollView',
  TouchableOpacity: 'TouchableOpacity',
  Dimensions: {
    get: jest.fn().mockReturnValue({ width: 375, height: 812 }),
  },
  Platform: {
    OS: 'ios',
    select: jest.fn((obj: Record<string, unknown>) => obj.ios),
  },
  StyleSheet: {
    create: (styles: Record<string, unknown>) => styles,
    flatten: jest.fn((style: unknown) => style),
  },
}));

import RNImageCarousel from '../index';
import type { RNImageCarouselRef } from '../index';

// Mock data
const mockData = [
  { imgUrl: 'https://picsum.photos/id/237/536/354' },
  { imgUrl: 'https://picsum.photos/seed/picsum/536/354' },
  { imgUrl: 'https://picsum.photos/id/1084/536/354?grayscale' },
];

// Tests
describe('RNImageCarousel', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders with correct props', () => {
    const mockOnPressImage = jest.fn();
    const mockOnChangeIndex = jest.fn();

    const { getByTestId } = render(
      <RNImageCarousel
        data={mockData}
        autoPlay={true}
        interval={2000}
        testID="carousel"
        onPressImage={mockOnPressImage}
        onChangeIndex={mockOnChangeIndex}
      />
    );

    const carousel = getByTestId('carousel');
    expect(carousel.props.data).toEqual(mockData.map((item) => item.imgUrl));
    expect(carousel.props.autoPlay).toBe(true);
    expect(carousel.props.interval).toBe(2000);

    // Simulate events
    fireEvent(carousel, 'pressImage', { nativeEvent: { index: 1 } });
    expect(mockOnPressImage).toHaveBeenCalledWith(mockData[1]);

    fireEvent(carousel, 'changeIndex', { nativeEvent: { index: 2 } });
    expect(mockOnChangeIndex).toHaveBeenCalledWith(2);
  });

  it('ref.scrollToIndex method calls native function', () => {
    const mockDispatchCommand = jest.spyOn(
      require('react-native').UIManager,
      'dispatchViewManagerCommand'
    );
    const mockFindNodeHandle = jest.spyOn(
      require('react-native'),
      'findNodeHandle'
    );

    const ref = React.createRef<RNImageCarouselRef>();

    render(
      <RNImageCarousel ref={ref} data={mockData} testID="carousel-with-ref" />
    );

    if (ref.current) {
      ref.current.scrollToIndex(2);

      expect(mockFindNodeHandle).toHaveBeenCalled();
      expect(mockDispatchCommand).toHaveBeenCalledWith(123, 'scrollToIndex', [
        2,
      ]);
    }
  });

  it('renders with default props', () => {
    const { getByTestId } = render(
      <RNImageCarousel data={mockData} testID="default-carousel" />
    );

    const carousel = getByTestId('default-carousel');
    expect(carousel.props.data).toEqual(mockData.map((item) => item.imgUrl));
    expect(carousel.props.autoPlay).toBeUndefined();
    expect(carousel.props.interval).toBeUndefined();
  });

  it('scrollToIndex returns early if findNodeHandle returns null', () => {
    const mockRN = require('react-native');
    const originalFindNodeHandle = mockRN.findNodeHandle;
    mockRN.findNodeHandle = jest.fn().mockReturnValue(null);

    const mockDispatchCommand = jest.spyOn(
      mockRN.UIManager,
      'dispatchViewManagerCommand'
    );

    const ref = React.createRef<RNImageCarouselRef>();

    render(
      <RNImageCarousel ref={ref} data={mockData} testID="null-node-carousel" />
    );

    if (ref.current) {
      ref.current.scrollToIndex(2);

      expect(mockDispatchCommand).not.toHaveBeenCalled();
    }

    mockRN.findNodeHandle = originalFindNodeHandle;
  });
});
