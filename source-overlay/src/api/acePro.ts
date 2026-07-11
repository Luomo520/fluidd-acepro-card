import axios from 'axios'

export interface AceApiStatusResponse extends Record<string, any> {}

export interface AceApiCommandPayload {
  command: string;
  params?: Record<string, string | number | boolean>;
}

function unwrapMoonrakerResult<T> (payload: any): T {
  if (payload?.result != null) {
    return payload.result as T
  }

  return payload as T
}

export async function getAceStatus (instance?: number): Promise<AceApiStatusResponse> {
  const response = await axios.get('/server/ace/status', {
    params: instance != null ? { instance } : undefined,
  })

  return unwrapMoonrakerResult<AceApiStatusResponse>(response.data)
}

export async function getAceSlots (instance?: number): Promise<Record<string, any>> {
  const response = await axios.get('/server/ace/slots', {
    params: instance != null ? { instance } : undefined,
  })

  return unwrapMoonrakerResult<Record<string, any>>(response.data)
}

export async function runAceCommand (payload: AceApiCommandPayload): Promise<Record<string, any>> {
  const response = await axios.post('/server/ace/command', payload)
  return unwrapMoonrakerResult<Record<string, any>>(response.data)
}

export async function probeAceApi (): Promise<boolean> {
  try {
    await getAceStatus()
    return true
  } catch (error: any) {
    return error?.response?.status !== 404
      ? Promise.reject(error)
      : false
  }
}
