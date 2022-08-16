<template>
  <div class="bx--grid bx--grid--full-width">
    <div class="bx--row">
      <div class="bx--col-lg-16 page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </div>
    </div>
    <div v-if="error.getConfiguration" class="bx--row">
      <div class="bx--col">
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </div>
    </div>
    <div class="bx--row">
      <div class="bx--col-lg-16">
        <cv-tile :light="true">
          <cv-form @submit.prevent="configureModule">
            <cv-text-input
              :label="$t('settings.roundcubemail_fqdn')"
              placeholder="roundcubemail.example.org"
              v-model.trim="host"
              class="mg-bottom"
              :invalid-message="$t(error.host)"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="host"
            >
            </cv-text-input>
            <cv-toggle
              value="letsEncrypt"
              :label="$t('settings.lets_encrypt')"
              v-model="isLetsEncryptEnabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <cv-toggle
              value="httpToHttps"
              :label="$t('settings.http_to_https')"
              v-model="isHttpToHttpsEnabled"
              :disabled="loading.getConfiguration || loading.configureModule"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <cv-text-input
              :label="$t('settings.mail_server_fqdn')"
              placeholder="mail.example.org"
              v-model.trim="mail_server"
              class="mg-bottom"
              :invalid-message="$t(error.mail_server)"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="mail_server"
            >
            </cv-text-input>
            <cv-combo-box
              v-model="encrypt_imap"
              :label="$t('setttings.choose')"
              :title="$t('settings.encrypt_imap')"
              :auto-filter="true"
              :auto-highlight="true"
              :options="options"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="error.encrypt_imap"
              light
              ref="encrypt_imap"
            >
            </cv-combo-box>
            <cv-text-input
              :label="$t('settings.imap_port')"
              placeholder="143"
              v-model.trim="imap_port"
              class="mg-bottom"
              :invalid-message="$t(error.imap_port)"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="imap_port"
            >
            </cv-text-input>
            <template v-if="encrypt_imap != 'none'">
              <cv-toggle
                value="tls_verify_imap"
                :label="$t('settings.tls_verify_imap')"
                v-model="is_tls_verify_imap"
                :disabled="loading.getConfiguration || loading.configureModule"
                class="mg-bottom"
              >
                <template slot="text-left">{{
                  $t("settings.disabled")
                }}</template>
                <template slot="text-right">{{
                  $t("settings.enabled")
                }}</template>
              </cv-toggle>
            </template>
            <cv-combo-box
              v-model="encrypt_smtp"
              :label="$t('setttings.choose')"
              :title="$t('settings.encrypt_smtp')"
              :auto-filter="true"
              :auto-highlight="true"
              :options="options"
              :disabled="loading.getConfiguration || loading.configureModule"
              :invalid-message="error.encrypt_smtp"
              light
              ref="encrypt_imap"
            >
            </cv-combo-box>
            <cv-text-input
              :label="$t('settings.smtp_port')"
              placeholder="587"
              v-model.trim="smtp_port"
              class="mg-bottom"
              :invalid-message="$t(error.smtp_port)"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="smtp_port"
            >
            </cv-text-input>
            <template v-if="encrypt_smtp != 'none'">
              <cv-toggle
                value="tls_verify_smtp"
                :label="$t('settings.tls_verify_smtp')"
                v-model="is_tls_verify_smtp"
                :disabled="loading.getConfiguration || loading.configureModule"
                class="mg-bottom"
              >
                <template slot="text-left">{{
                  $t("settings.disabled")
                }}</template>
                <template slot="text-right">{{
                  $t("settings.enabled")
                }}</template>
              </cv-toggle>
            </template>
            <!-- advanced options -->
            <cv-accordion ref="accordion" class="maxwidth mg-bottom">
              <cv-accordion-item :open="toggleAccordion[0]">
                <template slot="title">{{ $t("settings.advanced") }}</template>
                <template slot="content">
                  <cv-text-input
                    :label="$t('settings.plugins')"
                    placeholder="archive,zipdownload,managesieve,markasjunk"
                    v-model.trim="plugins"
                    class="mg-bottom"
                    :invalid-message="$t(error.plugins)"
                    :disabled="loading.getConfiguration || loading.configureModule"
                    ref="plugins"
                  >
                  </cv-text-input>
                  <cv-text-input
                    :label="$t('settings.upload_max_filesize')"
                    placeholder="5"
                    v-model.trim="upload_max_filesize"
                    class="mg-bottom"
                    :invalid-message="$t(error.upload_max_filesize)"
                    :disabled="loading.getConfiguration || loading.configureModule"
                    ref="upload_max_filesize"
                  >
                  </cv-text-input>
                </template>
              </cv-accordion-item>
            </cv-accordion>
            <div v-if="error.configureModule" class="bx--row">
              <div class="bx--col">
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </div>
            </div>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="loading.getConfiguration || loading.configureModule"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </div>
    </div>
  </div>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService
} from "@nethserver/ns8-ui-lib";

export default {
  name: "Settings",
  mixins: [TaskService, IconService, UtilService, QueryParamService,PageTitleService],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      urlCheckInterval: null,
      host: "",
      isLetsEncryptEnabled: false,
      isHttpToHttpsEnabled: true,
      is_tls_verify_imap: false,
      is_tls_verify_smtp: false,
      encrypt_imap: "starttls",
      encrypt_smtp: "starttls",
      imap_port: "143",
      smtp_port: "587",
      mail_server: "",
      plugins: "",
      upload_max_filesize:"5",
      options:[
        {
          name: "none",
          label: this.$t("settings.none"),
          value: "none",
        },
        {
          name: "starttls",
          label: this.$t("settings.starttls"),
          value: "starttls",
        },
        {
          name: "tls",
          label: this.$t("settings.tls"),
          value: "tls",
        },
      ],
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        lets_encrypt: "",
        http2https: "",
        mail_server:"",
        encrypt_imap: "",
        encrypt_smtp: "",
        imap_port: "",
        smtp_port: "",
        plugins: "",
        upload_max_filesize:""
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
  },
  created() {
    this.getConfiguration();
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  methods: {
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";

      // register to task error
      this.core.$root.$off(taskAction + "-aborted");
      this.core.$root.$once(
        taskAction + "-aborted",
        this.getConfigurationAborted
      );

      // register to task completion
      this.core.$root.$off(taskAction + "-completed");
      this.core.$root.$once(
        taskAction + "-completed",
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.core.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      const config = taskResult.output;
      this.host = config.host;
      this.isLetsEncryptEnabled = config.lets_encrypt;
      this.isHttpToHttpsEnabled = config.http2https;
      this.is_tls_verify_imap = config.tls_verify_imap;
      this.is_tls_verify_smtp = config.tls_verify_smtp;
      this.encrypt_imap = config.encrypt_imap;
      this.encrypt_smtp = config.encrypt_smtp;
      this.imap_port = config.imap_port;
      this.smtp_port = config.smtp_port;
      this.upload_max_filesize = config.upload_max_filesize;
      this.mail_server = config.mail_server;
      this.plugins = config.plugins;
      this.loading.getConfiguration = false;
      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);

      let isValidationOk = true;

      if (!this.mail_server) {
        this.error.mail_server = "common.required";

        if (isValidationOk) {
          this.focusElement("mail_server");
        }
        isValidationOk = false;
      }

      if (!this.host) {
        this.error.host = "common.required";

        if (isValidationOk) {
          this.focusElement("host");
        }
        isValidationOk = false;
      }

      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusAlreadySet = false;

      for (const validationError of validationErrors) {
        const param = validationError.parameter;
        // set i18n error message
        this.error[param] = "settings." + validationError.error;

        if (!focusAlreadySet) {
          this.focusElement(param);
          focusAlreadySet = true;
        }
      }
    },
    async configureModule() {
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";

      // register to task error
      this.core.$root.$off(taskAction + "-aborted");
      this.core.$root.$once(
        taskAction + "-aborted",
        this.configureModuleAborted
      );

      // register to task validation
      this.core.$root.$off(taskAction + "-validation-failed");
      this.core.$root.$once(
        taskAction + "-validation-failed",
        this.configureModuleValidationFailed
      );

      // register to task completion
      this.core.$root.$off(taskAction + "-completed");
      this.core.$root.$once(
        taskAction + "-completed",
        this.configureModuleCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            lets_encrypt: this.isLetsEncryptEnabled,
            http2https: this.isHttpToHttpsEnabled,
            tls_verify_imap:  this.is_tls_verify_imap,
            tls_verify_smtp: this.is_tls_verify_smtp,
            encrypt_imap: this.encrypt_imap,
            encrypt_smtp: this.encrypt_smtp,
            imap_port: parseInt(this.imap_port),
            smtp_port: parseInt(this.smtp_port),
            mail_server: this.mail_server,
            plugins: this.plugins,
            upload_max_filesize: this.upload_max_filesize

          },
          extra: {
            title: this.$t("settings.instance_configuration", {
              instance: this.instanceName,
            }),
            description: this.$t("settings.configuring"),
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
        return;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.core.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;

      // reload configuration
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.mg-bottom {
  margin-bottom: $spacing-06;
}

  .maxwidth {
    max-width: 38rem;
  }

</style>
