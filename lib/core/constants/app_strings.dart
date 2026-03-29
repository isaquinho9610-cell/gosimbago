class AppStrings {
  AppStrings._();

  static const appTitle = '국제처 업무관리';

  // Navigation
  static const navHome = '홈';
  static const navDailyTodo = '오늘 할일';
  static const navNewTask = '새 업무';
  static const navSettings = '설정';

  // Categories
  static const categoryAgreement = '협약관리';
  static const categoryDispatch = '파견업무';
  static const categoryProtocol = '의전';
  static const categoryOther = '기타업무';
  static const categoryProject = '프로젝트';

  // Subtypes
  static const subtypeMou = 'MoU';
  static const subtypeSea = 'SEA';
  static const subtypeLongTerm = '장기교환';
  static const subtypeShortTerm = '단기파견';
  static const subtypeGuestMeeting = '손님 미팅';
  static const subtypeMeetingMinutes = '회의록';

  // Status
  static const statusPending = '대기';
  static const statusInProgress = '진행중';
  static const statusCompleted = '완료';

  // Priority
  static const priorityHigh = '높음';
  static const priorityMedium = '보통';
  static const priorityLow = '낮음';

  // Actions
  static const actionAdd = '추가';
  static const actionEdit = '수정';
  static const actionDelete = '삭제';
  static const actionSave = '저장';
  static const actionCancel = '취소';
  static const actionComplete = '완료 처리';

  // Task form
  static const fieldTitle = '업무명';
  static const fieldDescription = '내용';
  static const fieldDueDate = '마감일';
  static const fieldPriority = '우선순위';
  static const fieldCategory = '업무 분류';
  static const fieldAddToDailyTodo = '오늘 할일에 추가';

  // Follow-up
  static const followUp = '팔로우업';
  static const followUpAdd = '팔로우업 추가';
  static const followUpEmpty = '팔로우업이 없습니다';

  // AI
  static const aiSummary = 'AI 요약';
  static const aiGenerate = 'AI 요약 생성';
  static const aiLoading = '분석 중...';
  static const aiError = 'AI 요약 생성 실패';

  // Settings
  static const settingsTitle = '설정';
  static const settingsApiKey = 'OpenRouter API 키';
  static const settingsApiKeyHint = 'sk-or-...';
  static const settingsApiKeySaved = 'API 키가 저장되었습니다';

  // Empty states
  static const emptyTasks = '등록된 업무가 없습니다\n+ 버튼으로 새 업무를 추가하세요';
  static const emptyDailyTodo = '오늘 할일이 없습니다\n업무를 추가하거나 기존 업무를 할일에 등록하세요';

  // Misc
  static const noDueDate = '마감일 없음';
  static const allCategories = '전체';
}
