(() => {
  const form = document.querySelector('#request-form');
  if (!form) return;

  const steps = [...document.querySelectorAll('.form-step')];
  const nextButton = document.querySelector('#next-button');
  const backButton = document.querySelector('#back-button');
  const resultButton = document.querySelector('#result-button');
  const stepLabel = document.querySelector('#step-label');
  const progressBar = document.querySelector('#progress-bar');
  const errorBox = document.querySelector('#form-error');
  const resultPanel = document.querySelector('#result-panel');
  const resultContent = document.querySelector('#result-content');
  const copyButton = document.querySelector('#copy-result');
  const editButton = document.querySelector('#edit-result');

  let currentStep = 0;
  let plainTextResult = '';

  const value = (id) => document.querySelector(`#${id}`).value.trim();

  function setStep(index) {
    currentStep = Math.max(0, Math.min(index, steps.length - 1));
    steps.forEach((step, stepIndex) => {
      step.classList.toggle('is-active', stepIndex === currentStep);
    });
    stepLabel.textContent = `Шаг ${currentStep + 1} из ${steps.length}`;
    progressBar.style.width = `${((currentStep + 1) / steps.length) * 100}%`;
    backButton.disabled = currentStep === 0;
    nextButton.hidden = currentStep === steps.length - 1;
    resultButton.hidden = currentStep !== steps.length - 1;
    errorBox.textContent = '';

    const activeField = steps[currentStep].querySelector('textarea, select');
    activeField?.focus({ preventScroll: true });
  }

  function validateCurrentStep() {
    if (currentStep !== 0) return true;
    const observed = value('observed');
    if (observed.length < 10) {
      errorBox.textContent = 'Опишите наблюдаемый эпизод хотя бы одним предложением.';
      return false;
    }
    return true;
  }

  nextButton.addEventListener('click', () => {
    if (!validateCurrentStep()) return;
    setStep(currentStep + 1);
  });

  backButton.addEventListener('click', () => setStep(currentStep - 1));

  const labels = {
    observed: 'Наблюдаемый эпизод',
    interpretation: 'Моя интерпретация',
    feeling: 'Моя реакция',
    impulse: 'Первый импульс',
    action: 'Что я сделал(а)',
    stuck: 'Где я застрял(а)',
  };

  const helpTemplates = {
    understanding: [
      'Какие ещё гипотезы могут объяснить этот эпизод и каких данных мне не хватает, чтобы их проверить?',
      'Что в моём понимании случая опирается на наблюдения, а что пока остаётся предположением?',
      'На какие аспекты истории и текущей динамики стоит обратить внимание, чтобы точнее понимать происходящее?',
    ],
    reaction: [
      'Как моя реакция в этом эпизоде могла повлиять на контакт и что она может сообщать о процессе?',
      'Что именно вызывает во мне эту реакцию и как работать с ней, не разыгрывая её в отношениях с клиентом?',
      'Как отличить мою личную реакцию от отклика на происходящее в терапевтических отношениях?',
    ],
    relationship: [
      'Что может происходить в отношениях между мной и клиентом в этом эпизоде и как это исследовать безопасно?',
      'Какой повторяющийся паттерн взаимодействия здесь возможен и какую позицию я в нём занимаю?',
      'Как сохранить контакт и одновременно не поддерживать привычный для клиента способ отношений?',
    ],
    intervention: [
      'Какие варианты следующего вмешательства здесь возможны и по каким признакам выбрать между ними?',
      'Как проверить мою гипотезу, не усиливая давление на клиента и не торопясь с интерпретацией?',
      'Какой небольшой профессиональный эксперимент я могу провести на следующей встрече и что наблюдать?',
    ],
    ethics: [
      'Какие этические, профессиональные или связанные с безопасностью риски важно проверить в этой ситуации?',
      'Где проходят границы моей компетентности и какие дополнительные действия или консультации необходимы?',
      'Какая информация и какие договорённости нужны, чтобы принять профессионально обоснованное решение?',
    ],
    contract: [
      'Что в сеттинге или договорённостях могло повлиять на эту ситуацию и что следует прояснить с клиентом?',
      'Какие границы и ожидания сторон здесь остаются неявными и требуют обсуждения?',
      'Как изменить или подтвердить контракт так, чтобы он поддерживал рабочие отношения?',
    ],
  };

  const helpNames = {
    understanding: 'Понимание случая',
    reaction: 'Реакция психолога',
    relationship: 'Отношения и процесс',
    intervention: 'Выбор интервенции',
    ethics: 'Этика, границы или риск',
    contract: 'Сеттинг или контракт',
  };

  function addResultBlock(label, text) {
    if (!text) return;
    const block = document.createElement('div');
    block.className = 'result-block';

    const title = document.createElement('div');
    title.className = 'result-label';
    title.textContent = label;

    const content = document.createElement('div');
    content.textContent = text;

    block.append(title, content);
    resultContent.append(block);
  }

  function addRequestOptions(options) {
    const block = document.createElement('div');
    block.className = 'result-block';

    const title = document.createElement('div');
    title.className = 'result-label';
    title.textContent = 'Варианты запроса на супервизию';
    block.append(title);

    options.forEach((option, index) => {
      const card = document.createElement('div');
      card.className = 'request-option';
      const heading = document.createElement('strong');
      heading.textContent = `Вариант ${index + 1}`;
      const text = document.createElement('span');
      text.textContent = option;
      card.append(heading, text);
      block.append(card);
    });

    resultContent.append(block);
  }

  function buildResult() {
    const data = {
      observed: value('observed'),
      interpretation: value('interpretation'),
      feeling: value('feeling'),
      impulse: value('impulse'),
      action: value('action'),
      stuck: value('stuck'),
      helpType: value('help-type'),
    };

    const options = helpTemplates[data.helpType] || helpTemplates.understanding;
    resultContent.replaceChildren();

    Object.entries(labels).forEach(([key, label]) => addResultBlock(label, data[key]));
    addResultBlock('Основной фокус', helpNames[data.helpType]);
    addRequestOptions(options);

    const textParts = ['Материал для супервизии'];
    Object.entries(labels).forEach(([key, label]) => {
      if (data[key]) textParts.push(`${label}: ${data[key]}`);
    });
    textParts.push(`Основной фокус: ${helpNames[data.helpType]}`);
    textParts.push('Варианты запроса:');
    options.forEach((option, index) => textParts.push(`${index + 1}. ${option}`));
    plainTextResult = textParts.join('\n\n');

    form.hidden = true;
    resultPanel.hidden = false;
    resultPanel.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  form.addEventListener('submit', (event) => {
    event.preventDefault();
    if (!validateCurrentStep()) return;
    buildResult();
  });

  editButton.addEventListener('click', () => {
    resultPanel.hidden = true;
    form.hidden = false;
    setStep(0);
    form.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });

  copyButton.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(plainTextResult);
      copyButton.textContent = '✓';
      copyButton.setAttribute('aria-label', 'Результат скопирован');
      setTimeout(() => {
        copyButton.textContent = '⧉';
        copyButton.setAttribute('aria-label', 'Скопировать результат');
      }, 1600);
    } catch {
      const area = document.createElement('textarea');
      area.value = plainTextResult;
      area.style.position = 'fixed';
      area.style.opacity = '0';
      document.body.append(area);
      area.select();
      document.execCommand('copy');
      area.remove();
    }
  });

  setStep(0);
})();
