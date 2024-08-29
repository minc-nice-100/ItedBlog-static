let timelife = [
    {title: '今日已经过去', endTitle: '小时', num: 0, percent: '0%'},
    {title: '这周已经过去', endTitle: '天', num: 0, percent: '0%'},
    {title: '本月已经过去', endTitle: '天', num: 0, percent: '0%'},
    {title: '今年已经过去', endTitle: '个月', num: 0, percent: '0%'}
];
{
    let nowDate = +new Date();
    let todayStartDate = new Date(new Date().toLocaleDateString()).getTime();
    let todayPassHours = (nowDate - todayStartDate) / 1000 / 60 / 60;
    let todayPassHoursPercent = (todayPassHours / 24) * 100;
    timelife[0].num = parseInt(todayPassHours);
    timelife[0].percent = parseInt(todayPassHoursPercent) + '%';
}
{
    let weeks = {0: 7, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6};
    let weekDay = weeks[new Date().getDay()];
    let weekDayPassPercent = (weekDay / 7) * 100;
    timelife[1].num = parseInt(weekDay);
    timelife[1].percent = parseInt(weekDayPassPercent) + '%';
}
{
    let year = new Date().getFullYear();
    let date = new Date().getDate();
    let month = new Date().getMonth() + 1;
    let monthAll = new Date(year, month, 0).getDate();
    let monthPassPercent = (date / monthAll) * 100;
    timelife[2].num = date;
    timelife[2].percent = parseInt(monthPassPercent) + '%';
}
{
    let month = new Date().getMonth() + 1;
    let yearPass = (month / 12) * 100;
    timelife[3].num = month;
    timelife[3].percent = parseInt(yearPass) + '%';
}
let htmlStr = '';
timelife.forEach((item, index) => {
    htmlStr += `
						<div class="item">
							<div class="title">
								${item.title}
								<span class="text">${item.num}</span>
								${item.endTitle}
							</div>
							<div class="progress">
								<div class="progress-bar">
									<div class="progress-bar-inner progress-bar-inner-${index}" style="width: ${item.percent}"></div>
								</div>
								<div class="progress-percentage">${item.percent}</div>
							</div>
						</div>`;
});

$('.joe_aside__item.timelife .joe_aside__item-contain').html(htmlStr);
		