// Jest 전역 변수 문제 해결
const jestFn = function () {
  const fn = function () {
    return fn;
  };
  fn.mockReturnThis = function () {
    return fn;
  };
  fn.mockReturnValue = function () {
    return fn;
  };
  fn.mockImplementation = function () {
    return fn;
  };
  fn.mockClear = function () {
    return fn;
  };
  return fn;
};

// 콘솔 경고 억제
global.console = {
  ...console,
  error: jestFn(),
  warn: jestFn(),
  log: jestFn(),
  debug: jestFn(),
};

// React Native 모킹
const ReactNativeMock = {
  // 기본 컴포넌트
  View: 'View',
  Text: 'Text',
  Image: 'Image',
  ScrollView: 'ScrollView',
  TouchableOpacity: 'TouchableOpacity',
  ActivityIndicator: 'ActivityIndicator',

  // 우리 컴포넌트에 필요한 것들
  requireNativeComponent: function () {
    return 'NativeImageCarousel';
  },
  UIManager: {
    getViewManagerConfig: function () {
      return {
        Commands: {
          scrollToIndex: 'scrollToIndex',
        },
      };
    },
    dispatchViewManagerCommand: jestFn(),
  },
  findNodeHandle: function () {
    return 123;
  },

  // 애니메이션 최소 모킹
  Animated: {
    createAnimatedComponent: function (comp) {
      return comp;
    },
    Value: function () {
      return {
        interpolate: jestFn(),
        setValue: jestFn(),
      };
    },
    timing: function () {
      return {
        start: jestFn(),
      };
    },
    spring: function () {
      return {
        start: jestFn(),
      };
    },
    loop: jestFn(),
  },
};
