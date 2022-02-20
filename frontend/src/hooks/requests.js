const API_URL = '';

// Submit inventory paste data.
async function httpPostEstimate (data) {
  try {
    const response = await fetch(`${API_URL}/estimate`, {
      method: "post",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    })
    return response.json();
  }
  catch (err) {
    console.error('req err', err)
    return {
      ok: false,
    };
  }
}

export {
  httpPostEstimate
};