// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '家計簿';

  @override
  String get settingsTitle => '設定';

  @override
  String get requireAuth => '認証が必要';

  @override
  String get requireAuthDesc => '指紋またはPINでアプリをロック';

  @override
  String get themeMode => 'テーマ';

  @override
  String currentTheme(String mode) {
    return '現在: $mode';
  }

  @override
  String get currency => '通貨';

  @override
  String currentCurrency(String name, String code, String symbol) {
    return '現在: $name ($code $symbol)';
  }

  @override
  String get language => '言語';

  @override
  String get restartTour => 'ガイドツアーを再開';

  @override
  String get restartTourDesc => '機能ごとのステップバイステップのツアーを再生';

  @override
  String get shareFeedback => 'フィードバックと提案の共有';

  @override
  String get shareFeedbackDesc => '体験を評価し、機能に投票';

  @override
  String get backupData => 'データのバックアップ';

  @override
  String get backupDataDesc => 'データを安全なファイルに保存';

  @override
  String get restoreData => 'データの復元';

  @override
  String get restoreDataDesc => '現在のデータをバックアップファイルで置き換え';

  @override
  String get manageWallets => 'ウォレットの管理';

  @override
  String get manageWalletsDesc => 'アカウントと初期残高を設定';

  @override
  String get manageBudgets => '予算の管理';

  @override
  String get manageBudgetsDesc => 'カテゴリーごとの月額カスタム制限を設定';

  @override
  String get manageCategories => 'カテゴリーの管理';

  @override
  String get manageCategoriesDesc => 'カスタムカテゴリーの追加または削除';

  @override
  String get backupSuccess => 'バックアップが保存されました。後で復元するためにこのファイルを安全に保管してください。';

  @override
  String get backupCancelled => 'バックアップがキャンセルされました。';

  @override
  String backupFailed(String error) {
    return 'バックアップ失敗: $error';
  }

  @override
  String get restoreDialogTitle => 'バックアップから復元しますか？';

  @override
  String get restoreDialogContent =>
      'これにより、アプリ内の現在のすべてのデータがバックアップファイルの内容に置き換えられます。この操作は元に戻せません。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get restore => '復元';

  @override
  String get restoreSuccess => 'バックアップの復元に成功しました。';

  @override
  String restoreFailed(String error) {
    return '復元失敗: $error';
  }

  @override
  String get tourStarted => 'ガイドツアーが開始されました！';

  @override
  String get feedbackError => 'フィードバックフォームを開けませんでした';

  @override
  String get myWallets => 'マイウォレット';

  @override
  String get noWalletsConfigured => 'ウォレットが設定されていません';

  @override
  String get totalSpentThisMonth => '今月の合計支出';

  @override
  String get income => '収入';

  @override
  String get expenses => '支出';

  @override
  String get savings => '貯金';

  @override
  String percentSaved(String percent) {
    return '$percent% 貯金';
  }

  @override
  String get overspent => '使いすぎ';

  @override
  String get upcomingBills => '今後の請求';

  @override
  String pendingBills(String count) {
    return '残り $count 件';
  }

  @override
  String get noUpcomingBills => '今月の残りに予定されている請求はありません。🎉';

  @override
  String get emi => '分割払い';

  @override
  String get sub => 'サブスク';

  @override
  String get dueToday => '本日が期限';

  @override
  String get dueTomorrow => '明日が期限';

  @override
  String dueOn(String date) {
    return '期限: $date';
  }

  @override
  String get totalCommitted => '確定済みの合計金額';

  @override
  String get recentTransactions => '最近の取引';

  @override
  String get seeAll => 'すべて見る';

  @override
  String get addedFunds => '追加された資金';

  @override
  String editBudget(String categoryName) {
    return '予算の編集: $categoryName';
  }

  @override
  String get monthlyBudgetLimit => '月間予算制限';

  @override
  String get pleaseEnterAmount => '金額を入力してください';

  @override
  String get pleaseEnterValidNumber => '有効な正の数を入力してください';

  @override
  String get clear => 'クリア';

  @override
  String budgetCleared(String categoryName) {
    return '$categoryName の予算がクリアされました。';
  }

  @override
  String get save => '保存';

  @override
  String budgetSet(String categoryName, String amount) {
    return '$categoryName の予算が $amount に設定されました。';
  }

  @override
  String get budgets => '予算';

  @override
  String get manage => '管理';

  @override
  String get noBudgetsSet => 'まだ予算が設定されていません。管理をタップして追跡したいカテゴリーの月間制限を設定してください。';

  @override
  String overBudget(String amount) {
    return '予算を $amount オーバーしています';
  }

  @override
  String remaining(String amount) {
    return '残り $amount';
  }

  @override
  String get spendingByCategory => 'カテゴリー別の支出';

  @override
  String get noSpendingData => '今月の支出データはありません。';

  @override
  String get total => '合計';

  @override
  String get savingsGoals => '貯金目標';

  @override
  String get noSavingsGoals => 'まだ貯金目標が設定されていません。\n目標タブで作成してください！';

  @override
  String get overdue => '期限切れ';

  @override
  String get completed => '完了！🎉';

  @override
  String get onTrack => '順調';

  @override
  String get inProgress => '進行中';

  @override
  String get justStarted => '開始したばかり';

  @override
  String get notEnoughDataForChart => 'トレンドチャートに十分なデータがありません。';

  @override
  String get incomeVsExpenses => '収入と支出の推移';

  @override
  String get mainBank => 'メインバンク';

  @override
  String get cash => '現金';

  @override
  String get validAmountPrompt => '有効な金額を入力してください。（例：2000）';

  @override
  String get cannotTransferToSameWallet => '同じウォレットには送金できません。';

  @override
  String get transfer => '振替';

  @override
  String transferTo(String walletName) {
    return '$walletName へ';
  }

  @override
  String transferFrom(String walletName) {
    return '$walletName から';
  }

  @override
  String get allowanceIncome => 'お小遣い・収入';

  @override
  String systemError(String error) {
    return 'システムエラー: $error';
  }

  @override
  String get editIncome => '収入の編集';

  @override
  String get editExpense => '支出の編集';

  @override
  String get addFundsToWallet => 'ウォレットに資金を追加';

  @override
  String get transferFunds => '資金の振替';

  @override
  String get addNewExpense => '新しい支出を追加';

  @override
  String get expense => '支出';

  @override
  String get amount => '金額';

  @override
  String get fromWallet => '振出元';

  @override
  String get toWallet => '振込先';

  @override
  String get walletPaymentMethod => 'ウォレット / 支払い方法';

  @override
  String get category => 'カテゴリー';

  @override
  String get noteOptional => 'メモ（任意）';

  @override
  String get updateTransaction => '取引の更新';

  @override
  String get saveTransaction => '取引の保存';

  @override
  String get createWallet => 'ウォレットを作成';

  @override
  String get walletName => 'ウォレット名';

  @override
  String get walletNameHint => '例: HDFCクレジットカード';

  @override
  String get pleaseEnterWalletName => 'ウォレット名を入力してください';

  @override
  String get walletNameExists => 'ウォレット名はすでに存在します';

  @override
  String get startingBalanceOptional => '開始残高（任意）';

  @override
  String get pleaseEnterValidBalance => '有効な開始残高を入力してください';

  @override
  String get create => '作成';

  @override
  String walletCreated(String walletName) {
    return 'ウォレット \"$walletName\" が正常に作成されました。';
  }

  @override
  String get renameWallet => 'ウォレットの名前を変更';

  @override
  String walletRenamed(String walletName) {
    return 'ウォレットの名前が \"$walletName\" に変更されました。';
  }

  @override
  String get cannotDelete => '削除できません';

  @override
  String get mustKeepOneWallet => 'アプリ内には少なくとも1つのアクティブなウォレットが必要です。';

  @override
  String get ok => 'OK';

  @override
  String get confirmDelete => '削除の確認';

  @override
  String confirmDeleteWalletMsg(String walletName) {
    return '\"$walletName\" を削除してもよろしいですか？\n\n注意：このウォレットにリンクされていた以前の取引は履歴に残りますが、アクティブなウォレットの残高には影響しません。';
  }

  @override
  String get delete => '削除';

  @override
  String walletDeleted(String walletName) {
    return 'ウォレット \"$walletName\" が削除されました。';
  }

  @override
  String get totalNetWorth => '純資産総額';

  @override
  String get balanceOverdrawn => '残高不足';

  @override
  String get availableBalance => '利用可能残高';

  @override
  String get addWallet => 'ウォレットを追加';

  @override
  String setBudgetFor(String categoryName) {
    return '予算を設定: $categoryName';
  }

  @override
  String get enterMonthlyBudgetLimit =>
      'このカテゴリーの月間予算上限を入力してください。アプリはこの上限に対する支出を追跡します。';

  @override
  String get budgetLimitTitle => '予算上限';

  @override
  String get budgetLimitHint => '例: 1000';

  @override
  String get clearBudget => '予算をクリア';

  @override
  String get noCategoriesFound => 'カテゴリーが見つかりません。';

  @override
  String customizedBudgetsCount(String count) {
    return 'カスタマイズされた予算: $count';
  }

  @override
  String get tapCategoryToSetBudget => 'カテゴリーをタップして、カスタム月間予算上限を設定または編集します。';

  @override
  String usingDefaultLimit(String amount) {
    return 'デフォルト上限を使用 ($amount)';
  }

  @override
  String confirmDeleteCategoryMsg(String categoryName) {
    return '\'$categoryName\' を削除してもよろしいですか？';
  }

  @override
  String categoryDeleted(String categoryName) {
    return '$categoryName が削除されました';
  }

  @override
  String get customCategory => 'カスタムカテゴリー';

  @override
  String get defaultCategory => 'デフォルトカテゴリー';

  @override
  String get newCategory => '新しいカテゴリー';

  @override
  String get createCategory => 'カテゴリーを作成';

  @override
  String get categoryName => 'カテゴリー名';

  @override
  String get selectColor => '色を選択';

  @override
  String get selectIcon => 'アイコンを選択';

  @override
  String get pleaseEnterName => '名前を入力してください';

  @override
  String get categoryAlreadyExists => 'カテゴリーはすでに存在します';

  @override
  String get tripSplits => '旅行の割り勘';

  @override
  String get noTripsYet => '旅行はまだありません';

  @override
  String get tapToCreateTrip => '「+」をタップして最初のグループ旅行を作成しましょう！';

  @override
  String get deleteTrip => '旅行を削除しますか？';

  @override
  String confirmDeleteTripMsg(String tripName) {
    return 'これにより「$tripName」とそのすべての支出が完全に削除されます。';
  }

  @override
  String expenseCountString(int count) {
    return '$count 件の支出';
  }

  @override
  String get newTrip => '新しい旅行';

  @override
  String get tripNameTitle => '旅行名';

  @override
  String get tripNameHint => '例: 日帰り旅行';

  @override
  String get addMember => 'メンバーを追加';

  @override
  String get memberHint => '例: 山田';

  @override
  String get typeNameToAdd => '名前を入力してEnterキーを押して追加';

  @override
  String membersAddedCount(int count) {
    return '$count 人のメンバーが追加されました';
  }

  @override
  String get enterTripName => '旅行名を入力してください！';

  @override
  String get addAtLeastTwoMembers => '少なくとも2人のメンバーを追加してください！';

  @override
  String memberAlreadyAdded(String name) {
    return '$name はすでに追加されています！';
  }

  @override
  String get settle => '清算する';

  @override
  String get removeMember => 'メンバーを削除';

  @override
  String get totalSpent => '合計支出';

  @override
  String tripMembersAndExpenses(int membersCount, int expensesCount) {
    return '$membersCount 人のメンバー · $expensesCount 件の支出';
  }

  @override
  String get balances => '残高';

  @override
  String get noExpensesYetTapPlus => '支出はまだありません。\n「+」をタップして最初の支出を追加してください！';

  @override
  String paidByAndSplit(String payer, int splitCount) {
    return '支払者: $payer · 割り勘: $splitCount人';
  }

  @override
  String get addExpenseTitle => '支出を追加';

  @override
  String get editExpenseTitle => '支出を編集';

  @override
  String get description => '説明';

  @override
  String get expenseDescHint => '例: 高速道路料金';

  @override
  String get paidByLabel => '支払者';

  @override
  String get splitAmong => '割り勘対象:';

  @override
  String get fillInAllFields => 'すべての項目を正しく入力してください！';

  @override
  String get selectAtLeastOnePerson => '割り勘する人を少なくとも1人選択してください！';

  @override
  String get add => '追加';

  @override
  String get update => '更新';

  @override
  String get nameLabel => '名前';

  @override
  String memberAlreadyInTrip(String name) {
    return '$name はすでに旅行に参加しています！';
  }

  @override
  String get tripNeedsTwoMembers => '旅行には少なくとも2人のメンバーが必要です！';

  @override
  String get tapMemberToRemove => 'メンバーをタップして削除します。';

  @override
  String inCountExpenses(int count) {
    return '$count 件の支出に参加';
  }

  @override
  String get notInAnyExpenses => 'どの支出にも参加していません';

  @override
  String removeMemberTitle(String member) {
    return '$member を削除しますか？';
  }

  @override
  String willAffectCountExpenses(int count) {
    return 'これにより $count 件の支出に影響が出ます。';
  }

  @override
  String get removeMemberWarningBody =>
      '• 彼らが支払った支出は削除されます\n• すべての割り勘から除外されます\n• 残りのメンバーの負担額が変更されます';

  @override
  String get remove => '削除';

  @override
  String memberRemoved(String member) {
    return '$member を削除しました';
  }

  @override
  String memberRemovedWithUpdates(String member, int count) {
    return '$member を削除しました · $count 件の支出が更新されました';
  }

  @override
  String get analyzingExpenses => '支出を分析中...';

  @override
  String get calculatingBalances => '残高を計算中...';

  @override
  String get optimizingTransfers => '送金を最適化中...';

  @override
  String get done => '完了！';

  @override
  String get calculatingSplits => '割り勘を計算中...';

  @override
  String get runningDebtOptimization => '負債最適化アルゴリズムを実行中';

  @override
  String get settleUp => '清算する';

  @override
  String get allSettled => 'すべて清算済み！';

  @override
  String get noOneOwesAnything => '誰にも貸し借りがありません。';

  @override
  String get allPaymentsDone => '🎉 すべての支払いが完了しました！';

  @override
  String paidOfTotal(int paidCount, int totalCount) {
    return '$totalCount件中 $paidCount件支払い済み';
  }

  @override
  String get everyoneSquaredUp => '全員の清算が完了しました！';

  @override
  String get optimizedForMinimumTransfers => '最小限の送金回数に最適化';

  @override
  String get pays => '支払う';

  @override
  String get receives => '受け取る';

  @override
  String get paidTapToUndo => '支払い済み ✓ (タップで取り消し)';

  @override
  String get markAsPaid => '支払い済みにする';

  @override
  String get individualBreakdown => '個別の内訳';

  @override
  String get paidCheck => '支払い済み ✓';

  @override
  String getsBackAmount(String amount) {
    return '$amount 受け取る';
  }

  @override
  String owesAmount(String amount) {
    return '$amount 支払う';
  }

  @override
  String get settled => '清算済み';

  @override
  String get notInAnySplits => 'どの割り勘にも参加していません';

  @override
  String get confirmPayment => '支払いを確認';

  @override
  String get hasPaidPart => ' は ';

  @override
  String get toPart => ' を ';

  @override
  String get questionMarkPart => ' に支払いましたか？';

  @override
  String get notYet => 'まだ';

  @override
  String get yesPaid => 'はい、支払いました！';

  @override
  String get edit => '編集';

  @override
  String get deleteSubscriptionTitle => 'サブスクリプションを削除しますか？';

  @override
  String deleteSubscriptionWarning(String name) {
    return '「$name」を削除します。すでに記録された取引は削除されません。';
  }

  @override
  String get recurringSubscriptions => '定期購読';

  @override
  String get noActiveSubscriptions => 'アクティブなサブスクリプションはありません。';

  @override
  String billedOnDay(int day, String method) {
    return '毎月 $day 日請求 • $method';
  }

  @override
  String get newSubscription => '新しいサブスクリプション';

  @override
  String get editSubscriptionTitle => 'サブスクリプションを編集';

  @override
  String get addSubscriptionTitle => 'サブスクリプションを追加';

  @override
  String get payFrom => '支払元';

  @override
  String get dayOfMonth => '支払い日';

  @override
  String get subscriptionNameHint => 'サブスクリプション名 (例: Netflix)';

  @override
  String get updateSubscription => 'サブスクリプションを更新';

  @override
  String get saveSubscription => 'サブスクリプションを保存';

  @override
  String get enterValidAmount => '有効な金額を入力してください。';

  @override
  String get thisRecurringCharge => 'この定期請求';

  @override
  String formattedNote(String note) {
    return '「$note」';
  }

  @override
  String get possibleDuplicateTitle => '重複の可能性';

  @override
  String possibleDuplicateWarning(String label) {
    return '$label と一致するサブスクリプションがすでにあります。追加しますか？';
  }

  @override
  String get addAnyway => '追加する';

  @override
  String errorMessage(String error) {
    return 'エラー: $error';
  }

  @override
  String deleteItemTitle(String type) {
    return '$typeを削除しますか？';
  }

  @override
  String itemWillBeRemovedPermanently(String name) {
    return '「$name」は完全に削除されます。';
  }

  @override
  String get goalsAndEmis => '目標とEMI';

  @override
  String get noCostEmisAndDebt => '金利なしのEMIと負債';

  @override
  String get noGoalsSetTapPlus => 'まだ目標が設定されていません。+ をタップして設定してください！';

  @override
  String get editGoal => '目標を編集';

  @override
  String get deleteGoal => '目標を削除';

  @override
  String amountSaved(String amount) {
    return '$amount 貯蓄済み';
  }

  @override
  String targetAmount(String amount) {
    return '目標: $amount';
  }

  @override
  String get addFunds => '資金を追加';

  @override
  String get noActiveEmisOrDebts => 'アクティブなEMIや負債はありません。';

  @override
  String get editEmi => 'EMIを編集';

  @override
  String get deleteEmi => 'EMIを削除';

  @override
  String monthlyInstallmentDay(String installment, int day) {
    return '$installment / 月 • $day 日';
  }

  @override
  String monthsPaidOfTotal(int paid, int total) {
    return '$total か月中 $paid か月支払い済み';
  }

  @override
  String totalAmountLabel(String amount) {
    return '合計: $amount';
  }

  @override
  String get editSavingsGoal => '貯蓄目標を編集';

  @override
  String get newSavingsGoal => '新しい貯蓄目標';

  @override
  String get goalNameHint => '目標名 (例: iPhone)';

  @override
  String get targetAmountLabel => '目標金額';

  @override
  String get colorLabel => '色:';

  @override
  String get updateGoal => '目標を更新';

  @override
  String get createGoal => '目標を作成';

  @override
  String get editNoCostEmi => '無金利EMIを編集';

  @override
  String get newNoCostEmi => '新しい無金利EMI';

  @override
  String get itemNameHint => 'アイテム名 (例: iPhone)';

  @override
  String get totalBillAmount => '合計請求額';

  @override
  String get totalDurationMonths => '合計期間 (月)';

  @override
  String get paymentDay => '支払い日';

  @override
  String get payFromWallet => '支払元ウォレット';

  @override
  String get updateEmi => 'EMIを更新';

  @override
  String get addEmiTracker => 'EMIトラッカーを追加';

  @override
  String depositToGoal(String goalName) {
    return '$goalName に入金';
  }

  @override
  String get amountToMoveToSavings => '貯蓄に移動する金額';

  @override
  String get withdrawFromWallet => '引き出し元 (ウォレット)';

  @override
  String get deposit => '入金';

  @override
  String get navHome => 'ホーム';

  @override
  String get navCharts => 'チャート';

  @override
  String get navSubs => '定期購読';

  @override
  String get navGoals => '目標';

  @override
  String get navSplit => '割り勘';

  @override
  String get analytics => '分析';

  @override
  String get thisMonth => '今月';

  @override
  String get lastMonth => '先月';

  @override
  String get last3Months => '過去3ヶ月';

  @override
  String get yearToDate => '年初来';

  @override
  String get editWallet => 'ウォレットを編集';

  @override
  String get adjustBalance => '残高を調整';

  @override
  String get adjustBalanceHint => '現在の残高を維持する場合は空欄のまま';

  @override
  String get newBalance => '新しい残高';

  @override
  String balanceAdjusted(String walletName) {
    return '$walletName の残高が調整されました';
  }

  @override
  String deleteWalletWarning(String count) {
    return 'このウォレットにリンクされた $count 件の取引もすべて削除されます。この操作は元に戻せません。';
  }
}
