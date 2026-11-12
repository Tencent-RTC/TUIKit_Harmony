import axios, { AxiosResponse } from '@ohos/axios';
import { url } from '@kit.ArkTS';
import { MMKV } from '@tencent/mmkv';
import { LoginStore } from '@tencentcloud/atomicxcore';
import { AIAssistantAgent, AIAssistantHandoffStatus } from '@tencentcloud/atomicx/src/main/ets/aiassistant/Index';
import DemoConstants from '../utils/DemoConstants';

interface AgentItem {
  id?: string;
  name?: string;
  welcome?: string;
  im_user_id?: string;
  im_nickname?: string;
}

interface AgentsResponse {
  agents?: AgentItem[];
}

interface HandoffStatusResponse {
  callable?: boolean;
  state?: string;
  seat_im_user_id?: string;
}

interface HandoffStatusRequest {
  user_id: string;
  usersig: string;
}

export class SupportAgentCatalog {
  private static readonly AGENTS_URL: string = 'https://md5.ltd/api/support/v1/agents';
  private static readonly HANDOFF_STATUS_PATH: string = '/api/im/handoff-status';
  private static readonly CONNECT_TIMEOUT_MS: number = 10000;
  private static readonly READ_TIMEOUT_MS: number = 15000;
  private static agentList: AIAssistantAgent[] = [];

  static get agents(): AIAssistantAgent[] {
    return SupportAgentCatalog.agentList;
  }

  static displayNameForConversation(conversationID: string): string | undefined {
    return SupportAgentCatalog.agentList
      .find((agent: AIAssistantAgent) => agent.conversationID === conversationID)?.displayName;
  }

  static fetch(onResult: (agents: AIAssistantAgent[]) => void): void {
    axios.get<string | AgentsResponse>(SupportAgentCatalog.AGENTS_URL, {
      timeout: SupportAgentCatalog.CONNECT_TIMEOUT_MS + SupportAgentCatalog.READ_TIMEOUT_MS,
      headers: { 'Cache-Control': 'no-store' }
    }).then((response: AxiosResponse<string | AgentsResponse>) => {
      if (response.status >= 200 && response.status < 300) {
        SupportAgentCatalog.agentList = SupportAgentCatalog.parse(response.data);
      }
      onResult(SupportAgentCatalog.agentList);
    }).catch(() => {
      onResult(SupportAgentCatalog.agentList);
    });
  }

  static fetchHandoffStatus(onResult: (status: AIAssistantHandoffStatus) => void): void {
    const handoffUrl = SupportAgentCatalog.handoffStatusUrl();
    const mmkv = MMKV.defaultMMKV();
    let userId = (LoginStore.shared().state.loginUserInfo?.userID ?? '').trim();
    if (userId.length === 0) {
      userId = (mmkv.decodeString(DemoConstants.LOGIN_USER_ID) ?? '').trim();
    }
    const userSig = (mmkv.decodeString(DemoConstants.LOGIN_USER_SIG) ?? '').trim();
    if (handoffUrl === undefined || userId.length === 0 || userSig.length === 0) {
      setTimeout(() => onResult(AIAssistantHandoffStatus.INACTIVE), 0);
      return;
    }
    const payload: HandoffStatusRequest = { user_id: userId, usersig: userSig };
    axios.post<string | HandoffStatusResponse>(handoffUrl, payload, {
      timeout: SupportAgentCatalog.CONNECT_TIMEOUT_MS + SupportAgentCatalog.READ_TIMEOUT_MS,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store'
      }
    }).then((response: AxiosResponse<string | HandoffStatusResponse>) => {
      if (response.status >= 200 && response.status < 300) {
        onResult(SupportAgentCatalog.parseHandoffStatus(response.data));
      } else {
        onResult(AIAssistantHandoffStatus.INACTIVE);
      }
    }).catch(() => {
      onResult(AIAssistantHandoffStatus.INACTIVE);
    });
  }

  private static handoffStatusUrl(): string | undefined {
    try {
      return url.URL.parseURL(SupportAgentCatalog.HANDOFF_STATUS_PATH, SupportAgentCatalog.AGENTS_URL).toString();
    } catch (e) {
      return undefined;
    }
  }

  private static parse(body: string | AgentsResponse): AIAssistantAgent[] {
    let root: AgentsResponse | undefined;
    if (typeof body === 'string') {
      try {
        root = JSON.parse(body) as AgentsResponse;
      } catch (e) {
        return [];
      }
    } else {
      root = body;
    }
    const items = root?.agents;
    if (!Array.isArray(items)) {
      return [];
    }
    const result: AIAssistantAgent[] = [];
    for (const item of items) {
      if (!item) {
        continue;
      }
      const imUserId = SupportAgentCatalog.text(item.im_user_id);
      if (imUserId.length === 0) {
        continue;
      }
      result.push(new AIAssistantAgent(
        SupportAgentCatalog.text(item.id),
        SupportAgentCatalog.text(item.name),
        SupportAgentCatalog.text(item.welcome),
        imUserId,
        SupportAgentCatalog.text(item.im_nickname)
      ));
    }
    return result;
  }

  private static parseHandoffStatus(body: string | HandoffStatusResponse): AIAssistantHandoffStatus {
    let root: HandoffStatusResponse | undefined;
    if (typeof body === 'string') {
      try {
        root = JSON.parse(body) as HandoffStatusResponse;
      } catch (e) {
        return AIAssistantHandoffStatus.INACTIVE;
      }
    } else {
      root = body;
    }
    if (!root) {
      return AIAssistantHandoffStatus.INACTIVE;
    }
    return new AIAssistantHandoffStatus(
      root.callable === true,
      SupportAgentCatalog.text(root.state),
      SupportAgentCatalog.text(root.seat_im_user_id)
    );
  }

  private static text(value?: string): string {
    return typeof value === 'string' ? value.trim() : '';
  }
}
