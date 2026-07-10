// 通知テキストから期限を抽出し "YYYY/M/D HH:MM" 形式で返す（抽出できなければ空文字）
// now: 年なし日付の年またぎ判定に使う現在時刻の Date
// ブラウザ注入（piccoma-reminder.applescript）と JXA テスト（extract-date.test.sh）で共用する
function extractDueDate(text, now) {
	if (!text) return '';

	// パターン1: YYYY/M/D(曜日)HH:MM または YYYY/M/D HH:MM
	let match = text.match(/([0-9]{4}\/[0-9]{1,2}\/[0-9]{1,2})[^0-9]*([0-9]{2}:[0-9]{2})/);
	if (match) return match[1] + ' ' + match[2];

	// パターン1b: 時刻なしの YYYY/M/D はその日いっぱいが期限とみなし 23:59 を補完
	match = text.match(/[0-9]{4}\/[0-9]{1,2}\/[0-9]{1,2}/);
	if (match) return match[0] + ' 23:59';

	// パターン2: M/D(曜日)HH:MM（年なしなので年を補完する）
	match = text.match(/([0-9]{1,2}\/[0-9]{1,2})\([^)]+\)([0-9]{2}:[0-9]{2})/);
	if (match) {
		const monthDay = match[1];
		const time = match[2];
		const parts = monthDay.split('/');
		const timeParts = time.split(':');
		const year = now.getFullYear();
		// 現在年で解釈して180日以上過去なら年またぎ（12月に見た1月期限など）とみなし翌年に補正する
		const candidate = new Date(year, Number(parts[0]) - 1, Number(parts[1]), Number(timeParts[0]), Number(timeParts[1]));
		const resolvedYear = candidate.getTime() < now.getTime() - 180 * 86400 * 1000 ? year + 1 : year;
		return resolvedYear + '/' + monthDay + ' ' + time;
	}

	return '';
}
