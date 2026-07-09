// Project URL / publishable key de Supabase (seguras de exponer en el navegador,
// el acceso real lo controlan las políticas RLS de cada tabla).
const SUPABASE_URL = "https://vdndznhhdipzsahnesif.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_bfKTF1DQ01foPY84HnMBiQ_iRyL3hAg";

(function () {
  const form = document.getElementById("waitlist-form");
  if (!form) return;

  const feedback = form.querySelector(".form-feedback");
  const submitBtn = form.querySelector("button[type='submit']");

  function setFeedback(message, state) {
    feedback.textContent = message;
    feedback.dataset.state = state;
  }

  form.addEventListener("submit", async function (event) {
    event.preventDefault();

    // Honeypot: los bots suelen rellenar todos los campos, las personas no ven este.
    if (form.website.value !== "") return;

    if (SUPABASE_URL === "SUPABASE_URL_AQUI" || SUPABASE_ANON_KEY === "SUPABASE_ANON_KEY_AQUI") {
      setFeedback("El formulario todavía no está conectado. Escríbenos directo a hola@parkflow.app mientras tanto.", "error");
      return;
    }

    const role = form.querySelector("input[name='role']:checked");
    const payload = {
      full_name: form.full_name.value.trim(),
      email: form.email.value.trim(),
      role: role ? role.value : null,
      message: form.message.value.trim() || null,
    };

    submitBtn.disabled = true;
    setFeedback("Enviando...", "pending");

    try {
      const res = await fetch(`${SUPABASE_URL}/rest/v1/waitlist_signups`, {
        method: "POST",
        headers: {
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
          "Content-Type": "application/json",
          Prefer: "return=minimal",
        },
        body: JSON.stringify(payload),
      });

      if (!res.ok) throw new Error(`status ${res.status}`);

      form.reset();
      setFeedback("Listo, ya quedaste anotado. Te escribimos apenas abramos el piloto.", "success");
    } catch (err) {
      setFeedback("No pudimos enviarlo. Intenta de nuevo o escríbenos a hola@parkflow.app.", "error");
    } finally {
      submitBtn.disabled = false;
    }
  });
})();
