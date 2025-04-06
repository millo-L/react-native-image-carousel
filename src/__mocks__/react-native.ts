// React Native 모듈 모킹
export const mockDispatchViewManagerCommand = jest.fn();
export const mockFindNodeHandle = jest.fn(() => 123);

const reactNative = {
  requireNativeComponent: jest.fn(() => 'NativeImageCarousel'),
  UIManager: {
    getViewManagerConfig: jest.fn(() => ({
      Commands: {
        scrollToIndex: 'scrollToIndex',
      },
    })),
    dispatchViewManagerCommand: mockDispatchViewManagerCommand,
  },
  findNodeHandle: mockFindNodeHandle,
};

export default reactNative;
